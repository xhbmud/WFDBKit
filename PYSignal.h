//
//  PYSignal.h
//  WFDBKit
//
//  Created by Richard Penwell on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "wfdb.h"


@interface PYSignal : NSObject {
	WFDB_Signal signal;
	
	WFDB_Frequency ffreq;	/* frame rate (frames/second) */
	WFDB_Frequency ifreq;	/* samples/second/signal returned by getvec */
	WFDB_Frequency sfreq;	/* samples/second/signal read by getvec */
	WFDB_Frequency cfreq;	/* counter frequency (ticks/second) */
	long btime;		/* base time (milliseconds since midnight) */
	WFDB_Date bdate;		/* base date (Julian date) */
	WFDB_Time nsamples;	/* duration of signals (in samples) */
	double bcount;		/* base count (counter value at sample 0) */
	long prolog_bytes;	/* length of prolog, as told to wfdbsetstart
						 
						 static int segments;		/* number of segments found by readheader() */
	int in_msrec;		/* current input record is: 0: a single-segment
								 record; 1: a multi-segment record */
	long msbtime;		/* base time for multi-segment record */
	WFDB_Date msbdate;	/* base date for multi-segment record */
	WFDB_Time msnsamples;	/* duration of multi-segment record */
	struct segrec {
		char recname[WFDB_MAXRNL+1];/* segment name */
		WFDB_Time nsamp;		/* number of samples in segment */
		WFDB_Time samp0;		/* sample number of first sample in segment */
	} *segarray, *segp, *segend;	/* beginning, current segment, end pointers */
	
	/* These variables relate to open input signals. */
	unsigned maxisig;	/* max number of input signals */
	unsigned maxigroup;	/* max number of input signal groups */
	unsigned nisig;		/* number of open input signals */
	unsigned nigroups;	/* number of open input signal groups */
	unsigned maxspf;		/* max allowed value for ispfmax */
	unsigned ispfmax;	/* max number of samples of any open signal
								 per input frame */
	struct isdata {		/* unique for each input signal */
		WFDB_Siginfo info;		/* input signal information */
		WFDB_Sample samp;		/* most recent sample read */
		int skew;			/* intersignal skew (in frames) */
	} **isd;
	struct igdata {		/* shared by all signals in a group (file) */
		int data;			/* raw data read by r*() */
		int datb;			/* more raw data used for bit-packed formats */
		WFDB_FILE *fp;		/* file pointer for an input signal group */
		long start;			/* signal file byte offset to sample 0 */
		int bsize;			/* if non-zero, all reads from the input file
							 are in multiples of bsize bytes */
		char *buf;			/* pointer to input buffer */
		char *bp;			/* pointer to next location in buf[] */
		char *be;			/* pointer to input buffer endpoint */
		char count;			/* input counter for bit-packed signal */
		char seek;			/* 0: do not seek on file, 1: seeks permitted */
		int stat;			/* signal file status flag */
	} **igd;
	WFDB_Sample *tvector;	/* getvec workspace */
	WFDB_Sample *uvector;	/* isgsettime workspace */
	WFDB_Sample *vvector;	/* tnextvec workspace */
	int tuvlen;		/* lengths of tvector and uvector in samples */
	WFDB_Time istime;	/* time of next input sample */
	int ibsize;		/* default input buffer size */
	unsigned skewmax;	/* max skew (frames) between any 2 signals */
	WFDB_Sample *dsbuf;	/* deskewing buffer */
	int dsbi;		/* index to oldest sample in dsbuf (if < 0,
							 dsbuf does not contain valid data) */
	unsigned dsblen;		/* capacity of dsbuf, in samples */
	unsigned framelen;	/* total number of samples per frame */
	int gvmode = DEFWFDBGVMODE;	/* getvec mode */
	int gvpad;		/* getvec padding (if non-zero, replace invalid
							 samples with previous valid samples) */
	int gvc;			/* getvec sample-within-frame counter */
	int isedf;		/* if non-zero, record is stored as EDF/EDF+ */
	WFDB_Sample *sbuf = NULL;	/* buffer used by sample() */
	int sample_vflag;	/* if non-zero, last value returned by sample()
								 was valid */
	
	/* These variables relate to output signals. */
	unsigned maxosig;	/* max number of output signals */
	unsigned maxogroup;	/* max number of output signal groups */
	unsigned nosig;		/* number of open output signals */
	unsigned nogroups;	/* number of open output signal groups */
	WFDB_FILE *oheader;	/* file pointer for output header file */
	struct osdata {		/* unique for each output signal */
		WFDB_Siginfo info;		/* output signal information */
		WFDB_Sample samp;		/* most recent sample written */
		int skew;			/* skew to be written by setheader() */
	} **osd;
	struct ogdata {		/* shared by all signals in a group (file) */
		int data;			/* raw data to be written by w*() */
		int datb;			/* more raw data used for bit-packed formats */
		WFDB_FILE *fp;		/* file pointer for output signal */
		long start;			/* byte offset to be written by setheader() */
		int bsize;			/* if non-zero, all writes to the output file
							 are in multiples of bsize bytes */
		char *buf;			/* pointer to output buffer */
		char *bp;			/* pointer to next location in buf[]; */
		char *be;			/* pointer to output buffer endpoint */
		char count;		/* output counter for bit-packed signal */
	} **ogd;
	WFDB_Time ostime;	/* time of next output sample */
	int obsize;		/* default output buffer size */
}

@end
