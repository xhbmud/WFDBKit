//
//  PYSignal.m
//  WFDBKit
//
//  Created by Richard Penwell on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PYSignal.h"


@implementation PYSignal

+ (PYSignal*)openSignalNumber:(NSInteger)recordNumber ofRecord:(PYRecording*)recording
{
    int navail, ngroups, nn;
    struct hsdata *hs;
    struct isdata *is;
    struct igdata *ig;
    WFDB_Signal s, si, sj;
    WFDB_Group g;
	
    /* Read the header and determine how many signals are available. */
    if ((navail = readheader(record)) <= 0) {
		if (navail == 0 && segments) {	/* this is a multi-segment record */
			in_msrec = 1;
			/* Open the first segment to get signal information. */
			if ((navail = readheader(segp->recname)) >= 0) {
				if (msbtime == 0L) msbtime = btime;
				if (msbdate == (WFDB_Date)0) msbdate = bdate;
			}
		}
    }
	
    /* If nsig <= 0, isigopen fills in up to (-nsig) members of siarray based
	 on the contents of the header, but no signals are actually opened.  The
	 value returned is the number of signals named in the header. */
    if (nsig <= 0) {
		nsig = -nsig;
		if (navail < nsig) nsig = navail;
		if (siarray != NULL)
			for (s = 0; s < nsig; s++)
				siarray[s] = hsd[s]->info;
		in_msrec = 0;	/* necessary to avoid errors when reopening */
		return (navail);
    }
	
    /* Determine how many new signals we should attempt to open.  The caller's
	 upper limit on this number is nsig, and the upper limit defined by the
	 header is navail. */
    if (nsig > navail) nsig = navail;
	
    /* Allocate input signals and signal group workspace. */
    nn = nisig + nsig;
    if (allocisig(nn) != nn)
		return (-1);	/* failed, nisig is unchanged, allocisig emits error */
    else
		nsig = nn;
    nn = nigroups + hsd[nsig-nisig-1]->info.group + 1;
    if (allocigroup(nn) != nn)
		return (-1);	/* failed, allocigroup emits error */
    else
		ngroups = nn;
	
    /* Set default buffer size (if not set already by setibsize). */
    if (ibsize <= 0) ibsize = BUFSIZ;
	
    /* Open the signal files.  One signal group is handled per iteration.  In
	 this loop, si counts through the entries that have been read from hsd,
	 and s counts the entries that have been added to isd. */
    for (g = si = s = 0; si < navail && s < nsig; si = sj) {
        hs = hsd[si];
		is = isd[nisig+s];
		ig = igd[nigroups+g];
		
		/* Find out how many signals are in this group. */
        for (sj = si + 1; sj < navail; sj++)
			if (hsd[sj]->info.group != hs->info.group) break;
		
		/* Skip this group if there are too few slots in the caller's array. */
		if (sj - si > nsig - s) continue;
		
		/* Set the buffer size and the seek capability flag. */
		if (hs->info.bsize < 0) {
			ig->bsize = hs->info.bsize = -hs->info.bsize;
			ig->seek = 0;
		}
		else {
			if ((ig->bsize = hs->info.bsize) == 0) ig->bsize = ibsize;
			ig->seek = 1;
		}
		SALLOC(ig->buf, 1, ig->bsize);
		
		/* Check that the signal file is readable. */
		if (hs->info.fmt == 0)
			ig->fp = NULL;	/* Don't open a file for a null signal. */
		else { 
			ig->fp = wfdb_open(hs->info.fname, (char *)NULL, WFDB_READ);
			/* Skip this group if the signal file can't be opened. */
			if (ig->fp == NULL) {
				SFREE(ig->buf);
				continue;
			}
		}
		
		/* All tests passed -- fill in remaining data for this group. */
		ig->be = ig->bp = ig->buf + ig->bsize;
		ig->start = hs->start;
		ig->stat = 1;
		while (si < sj && s < nsig) {
			copysi(&is->info, &hs->info);
			is->info.group = nigroups + g;
			is->skew = hs->skew;
			++s;
			if (++si < sj) {
				hs = hsd[si];
				is = isd[nisig + s];
			}
		}
		g++;
    }
	
    /* Produce a warning message if none of the requested signals could be
	 opened. */
    if (s == 0 && nsig)
		wfdb_error("isigopen: none of the signals for record %s is readable\n",
				   record);
	
    /* Copy the WFDB_Siginfo structures to the caller's array.  Use these
	 data to construct the initial sample vector, and to determine the
	 maximum number of samples per signal per frame and the maximum skew. */
    for (si = 0; si < s; si++) {
        is = isd[nisig + si];
		if (siarray) 
			copysi(&siarray[si], &is->info);
		is->samp = is->info.initval;
		if (ispfmax < is->info.spf) ispfmax = is->info.spf;
		if (skewmax < is->skew) skewmax = is->skew;
    }
    setgvmode(gvmode);	/* Reset sfreq if appropriate. */
    gvc = ispfmax;	/* Initialize getvec's sample-within-frame counter. */
    nisig += s;		/* Update the count of open input signals. */
    nigroups += g;	/* Update the count of open input signal groups. */
	
    if (sigmap_init() < 0)
		return (-1);
	
    /* Determine the total number of samples per frame. */
    for (si = framelen = 0; si < nisig; si++)
		framelen += isd[si]->info.spf;
	
    /* Allocate workspace for getvec, isgsettime, and tnextvec. */
    if (framelen > tuvlen) {
		SREALLOC(tvector, framelen, sizeof(WFDB_Sample));
		SREALLOC(uvector, framelen, sizeof(WFDB_Sample));
		if (nvsig > nisig) {
			int vframelen;
			for (si = vframelen = 0; si < nvsig; si++)
				vframelen += vsd[si]->info.spf;
			SREALLOC(vvector, vframelen, sizeof(WFDB_Sample));
		}
		else
			SREALLOC(vvector, framelen, sizeof(WFDB_Sample));
    }
    tuvlen = framelen;
	
    /* If deskewing is required, allocate the deskewing buffer (unless this is
	 a multi-segment record and dsbuf has been allocated already). */
    if (skewmax != 0 && (!in_msrec || dsbuf == NULL)) {
		dsbi = -1;	/* mark buffer contents as invalid */
		dsblen = framelen * (skewmax + 1);
		SALLOC(dsbuf, dsblen, sizeof(WFDB_Sample));
    }
}

@end
