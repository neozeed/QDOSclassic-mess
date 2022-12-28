;/*
A68k sub.asm
dcc -o L_QDOS L_QDOS.c -l hardware SUB.o
quit
*/
/* L_QDOS loads and runs QDOS */

#include <exec/exec.h>
#include <exec/libraries.h>
#include <dos/dos.h>
#include <intuition/intuition.h>
#include <workbench/workbench.h>
#include <stdio.h>
#include <hardware/cia.h>

#define MAXROMS 20

extern struct ExecBase *SysBase;
extern __far struct CIA ciaa, ciab;

typedef struct List		 LIST;
typedef struct Node		 NODE;
typedef struct MemHeader MEMHEADER;
typedef struct MemChunk  MEMCHUNK;

extern ULONG sub(),dummy();
extern ULONG subtoclear();

ULONG ql_lomem,ql_himem,ql_ssp,ql_var,rom_lomem;
int sflag,mflag,cflag,ccount,rflag,rcount,dflag;
ULONG qldate;

struct
{
  long day;
  long min;
  long tick;
} date;

struct rominfo
{
  char *name;
  VOID *fp;
  ULONG len;
  ULONG rlen;
};

struct memrange
{
  ULONG lomem;
  ULONG himem;
};

struct memrange *toclear;
struct rominfo rom[MAXROMS];

typedef struct CommandLineInterface CLI;
typedef struct Process PROCESS;

CLI	  *cli;
PROCESS *proc;

extern int	_start_();
extern int	_realstart_();

extern long _Detached_,   /* are we detached?	*/
				_WorkBench_,  /* are we on the WB?	*/
				_CLI_,		  /* are we on the CLI? */
				_Process_;	  /* are we a process?	*/
#if 1
/* how to change the default console (if it's used) */
char _DefaultConsole[] =
		 "CON:0/12/320/72/L_QDOS 2.06, loading QDOS...";
#endif

char VERSTAG[] = "\0$VER: L_QDOS 2.06";

shutdown(s) char *s;
{
  printf("%ls\n",s);
  if(_WorkBench_ || _Detached_)
  {
	 Delay(500);
  }
  exit(0);
}

usage()
{
  shutdown("L_QDOS v2.05\n\n"
			  "usage:\tL_QDOS [-r]\n"
					  "\t       [-q<QDOS rom>]\n"
					  "\t       [-p<MAIN rom>]\n"
					  "\t       [-m<lomem><+len|-himem>]\n"
					  "\t       [<OTHER roms>...]\n");
}

warning(s) char *s;
{
  printf("%ls\n",s);
}

char *
getnum(p,np) char *p; ULONG *np;
{ ULONG n,h;
  char c;
  c=*p++;
  n=0;
  if(c!='$')
  {
	 while(isdigit(c))
	 {
		h=c-48;
		n=n*10+h;
		c=*p++;
	 }
  }
  else
  {
	 c=*p++;
	 while(isxdigit(c))
	 {
		h=(c<58?c-48:(c<96?c-55:c-87));
		n=n*16+h;
		c=*p++;
	 }
  }
  *np=n;
  return --p;
}

doflags(p) char *p;
{
  ULONG num;
  while (*p != 0)
  { switch(toupper(*p++))
	 {
	 case 'D':
		dflag=1;
		break;
	 case 'R':
		rflag=1;
		break;
	 case 'Q':
		rom[0].name=p;
		while (*p!=0)
		  p++;
		break;
	 case 'P':
		rom[1].name=p;
		while (*p!=0)
		  p++;
		break;
	 case 'M':
		while(*p!=0)
		{ p=getnum(p,&num);
		  switch(*p)
		  {
		  case '+':
			 mflag=1;
			 ql_var=num;
			 break;
		  case '-':
			 mflag=2;
			 ql_var=num;
			 break;
		  case 0:
			 switch(mflag)
			 {
			 case 1:
				ql_himem=ql_var+num;
				break;
			 case 2:
				ql_himem=num;
				break;
			 default:
				usage();
			 }
			 break;
		  default:
			 usage();
		  }
		  if(*p!=0)
			 p++;
		}
		break;
	 default:
		usage();
	 }
  }
}

int
findrom(rom) struct rominfo *rom;
{
  ULONG len;
  VOID *f;
  char temp[80];
  f = fopen(rom->name,"r");
  if(f == 0)
  { strcpy(temp,rom->name);
	 strcat(temp," not available");
	 warning(temp);
	 len=0;
  }
  else
  { fseek(f,0,2);
	 len=ftell(f);
	 fseek(f,0,0);
  }
  rom->fp = f;
  rom->len=len;
  len+=255;
  len&=-256;
  rom->rlen=len;
  return len;
}

main(argc,argv)
int argc;
char **argv;
{
  int i,j,n;
  long olddir;
  ULONG rom_tot,rom_len,len,rom_dst,sub_len,sub_dst;
  char *p,*qp,*cp,**av;
  long GfxBase;

  MEMHEADER *mh;
  ULONG		mh_lower, mh_upper;

  _DetachFromCLI();		 /* Does just that. (Or nothing if */
								 /* run from the WorkBench).		  */

  _RunOnWorkBench(); 	 /* Indicates this program should  */
								 /* continue and will run properly */
								 /* if started from the WorkBench. */
								 /* Well, you say it will. 		  */

  _ToolTypeArgs();		 /* Means move tooltype array from */
								 /* .info file to argc,argv.		  */

  _OpenDefaultConsole(); /* Need this to use printf's etc  */
								 /* when starting from WorkBench   */
								 /* or if you've detached.         */
								 /* (You won't need it if you're   */
								 /* only using intuition stuff).   */
								 /* Does nothing if you're running */
								 /* on the CLI/Shell.				  */

  toclear=(struct memrange *)subtoclear;

  ccount=0;
  for (mh  = (MEMHEADER *)GetHead((LIST *)&SysBase->MemList);
		 mh != 0;
		 mh  = (MEMHEADER *)GetSucc((NODE *)mh))
  {
	 mh_lower=(ULONG)mh->mh_Lower;
	 mh_upper=(ULONG)mh->mh_Upper;
	 if (((ULONG)mh+sizeof(MEMHEADER))=mh_lower)
		mh_lower=(ULONG)mh;

	 if (ccount!=0)
		for (i=0;i<ccount;i++)
		  if (mh_lower<toclear[i].lomem)
		  {
			 n=mh_lower;mh_lower=toclear[i].lomem;toclear[i].lomem=n;
			 n=mh_upper;mh_upper=toclear[i].himem;toclear[i].himem=n;
		  }

	 toclear[ccount].lomem=mh_lower;
	 toclear[ccount].himem=mh_upper;
	 ccount++;

  }

  mflag=sflag=cflag=rflag=dflag=0;
  rcount=2;
  ql_lomem=rom_lomem=0;
  ql_himem=(toclear[ccount-1].himem)&(~511);
  ql_ssp=0x28480;
  ql_var=0x28000;

  for(i=1;i<argc;i++)
  {
#if 1
	 if (dflag!=0)
		printf("arg %ld = (%ld)'%ls'\n", i, strlen(argv[i]), argv[i]);
#endif
	 if (argv[i][0] == ' ')
		break;

	 if (argv[i][0] == '?')
		usage();

	 if (argv[i][0] == '-')
		doflags(argv[i]+1);
	 else
	 {
		if(rcount<MAXROMS)
		{ rom[rcount].name=argv[i];
		  rcount++;
		}
		else
		  shutdown("too many roms");
	 }
  }
  if (dflag!=0)
	 warning("...now in debug mode");

  if(dflag!=0)
	 printf("to clear structure=$%lx $%lx\n\n",(ULONG)toclear,(ULONG)subtoclear);

  i=0;
  while ((i < ccount) && (ql_var > toclear[i].himem))
	 i++;

  if (i < ccount)
	 if (ql_var < toclear[i].lomem)
		ql_var = toclear[i].lomem;

  if(dflag!=0)
	 printf("0ql_var=$%lx\n",ql_var);

  i = ccount - 1;
  while ((i >= 0) && (ql_himem < toclear[i].lomem))
	 i--;

  if (i >= 0)
  {
	 if (ql_himem>toclear[i].himem)
		ql_himem=toclear[i].himem;
  }

  if (ql_himem > 0x1000000)
  {
	 if (ql_var < toclear[ccount-1].lomem)
		ql_var = toclear[ccount-1].lomem;
  }

  if(dflag!=0)
	 printf("1ql_var=$%lx\n",ql_var);

  if(dflag!=0)
  {
	 for (i = 0; i < ccount; i++)
		printf("%ld $%08lX $%08lX \n",
				 i,toclear[i].lomem,toclear[i].himem);
  }

  if(rom[0].name==0)
	 rom[0].name="QLboot:ROMs/SYS_cde";
  if(rom[1].name==0)
	 rom[1].name="QLboot:ROMs/MAIN_cde";
  rom_tot=0;
  for(i=0;i==0 || i<rcount;i++)
  { len=findrom(&rom[i]);
	 if((len==0)&&(i<2))
		shutdown("sorry but I can't load QDOS");
	 if(dflag!=0)
		printf("%ls\n",rom[i].name);

	 rom_tot+=len;
  }

  if(dflag!=0)
	 printf("total space req=$%lx/%ld\n",rom_tot,rom_tot);

  if(rom_tot!=0)
  {
	 p = (char *)malloc(rom_tot);
	 if(p==0)
		shutdown("no memory");
	 qp=p;
	 for(i=0;i<rcount;i++)
	 { if(rom[i].len!=0)
		{ fread(p,rom[i].len,1,rom[i].fp);
		  p+=rom[i].rlen;
		}
	 }
  }

  rom_len=rom_tot-rom[0].rlen-rom[1].rlen;

  if(dflag!=0)
  { printf("QDOS and ROMS source=$%lx\n",qp);
	 printf("QDOS len=$%lx\n",rom[0].rlen);
	 printf("MAIN len=$%lx\n",rom[1].rlen);
	 printf("ROMs len=$%lx\n\n",rom_len);
  }

  DateStamp(&date);
  qldate=date.day+365*17+4;
  qldate=qldate*(24*60*60/8);
  qldate<<=3;
  qldate+=(date.min*60);
  qldate+=(date.tick/50);
  if(dflag!=0)
  { printf("days=%ld mins=%ld ticks=%ld\n",date.day,date.min,date.tick);
	 printf("qldate=$%08lx\n",qldate);
  }

  if(dflag!=0)
	 printf("2ql_var=$%lx\n",ql_var);

  ql_var = (ql_var + 0x7FFF) & (~0x7FFF);
  ql_himem=ql_himem&(~511);

  rom_dst=(ql_himem-rom_len)&(~511);
  sub_len=(ULONG)dummy-(ULONG)sub;
  sub_dst=((ql_himem-rom_tot)&(~511))-sub_len;

  ql_himem=rom_dst;
  if(rflag!=0)
	 if(ql_himem>0x200000)
		ql_himem=ql_himem-rom[0].rlen+0x600;

  if(dflag!=0)
	 printf("rom_dst=$%lx\n",rom_dst);

  if(ql_var<0x28000)
	 ql_var=0x28000;

  ql_ssp=ql_var+0x480;
  ql_lomem=ql_ssp;

  if(dflag!=0)
	 printf("lomem=$%lx himem=$%lx\n\n",ql_lomem,ql_himem);


  if(ql_lomem>=ql_himem)
	 shutdown("bad value for memory range\n...might be out of memory\n ");

check_dst:
  if(((ULONG)qp <= sub_dst) && ((ULONG)qp + rom_tot > sub_dst))
	 sub_dst = (ULONG)qp - sub_len;
  if(((ULONG)sub<=sub_dst)&&((ULONG)sub+sub_len>sub_dst))
  { sub_dst=(ULONG)sub-sub_len;
	 goto check_dst;
  }
  if(dflag!=0)
	 printf("sub src=$%lx sub dst=$%lx sub len=$%lx\n\n"
			  ,(ULONG)sub,sub_dst,sub_len);

  i=0;
  while(i<ccount)
  {
	 if(toclear[i].lomem<rom[0].rlen)
	 { if(toclear[i].himem>rom[0].rlen)
		  toclear[i].lomem=rom[0].rlen;
		else
		  goto removerange;
	 }

	 if(toclear[i].lomem<0x1F400)
	 { if(toclear[i].himem>0x1F400)
		{ if(toclear[i].himem>(0x1F400+rom[1].rlen))
		  { if(ccount<8)
			 { toclear[ccount].lomem=0x1F400+rom[1].rlen;
				toclear[ccount].himem=toclear[i].himem;
				ccount++;
			 }
			 else
				shutdown("range too complex");
			 }

		  toclear[i].himem=0x1F400;
		}
	 }

	 if(toclear[i].lomem<sub_dst)
	 { if(toclear[i].himem>sub_dst)
		{ if(toclear[i].himem>(sub_dst+sub_len))
		  { if(ccount<8)
			 { toclear[ccount].lomem=sub_dst+sub_len;
				toclear[ccount].himem=toclear[i].himem;
				ccount++;
			 }
			 else
				shutdown("range too complex");
			 }

		  toclear[i].himem=sub_dst;
		}
	 }

	 if(toclear[i].lomem<rom_dst)
	 { if(toclear[i].himem>rom_dst)
		{ if(toclear[i].himem>(rom_dst+rom_len))
		  { if(ccount<8)
			 { toclear[ccount].lomem=rom_dst+rom_len;
				toclear[ccount].himem=toclear[i].himem;
				ccount++;
			 }
			 else
				shutdown("range too complex");
			 }

		  toclear[i].himem=rom_dst;
		}
	 }

	 if(toclear[i].lomem<ql_himem)
	 { if(toclear[i].himem>ql_himem)
		  toclear[i].himem=ql_himem;
	 }
	 else
		goto removerange;

	 if(toclear[i].lomem==toclear[i].himem)
		goto removerange;

	 i++;
	 goto endwhile;

	 removerange:
	 ccount--;
	 toclear[i].lomem=toclear[ccount].lomem;
	 toclear[i].himem=toclear[ccount].himem;
	 endwhile:
  }
  toclear[ccount].lomem=0;
  toclear[ccount].himem=0;

  if(dflag!=0)
  { i=0;
	 while(i<ccount)
	 { printf("range: lomem=$%lx himem=%lx\n"
				 ,toclear[i].lomem,toclear[i].himem);
		i++;
	 }
  }

  if(dflag!=0)
  { printf("vars=$%lx ssp=$%lx\n\n",ql_var,ql_ssp);
	 shutdown("quitting L_QDOS...\n");
  }

  GfxBase=0;
  if (!(GfxBase =
		OpenLibrary("graphics.library",0)))
	 goto die;

  LoadView(NULL);

  if (GfxBase)
	 CloseLibrary(GfxBase);

die:
  Forbid();
  Disable();
  OwnBlitter();
  while(WaitBlit());

  if(((struct Library *)SysBase)->lib_Version>=37)
	CacheControl(0,CACRF_EnableI|CACRF_EnableD|CACRF_IBE|CACRF_DBE);

/* deselect all drives								*/
  ciab.ciaprb|=CIAF_DSKSEL0|CIAF_DSKSEL1|CIAF_DSKSEL2|CIAF_DSKSEL3;
/* motor signal (off)								*/
  ciab.ciaprb|=CIAF_DSKMOTOR;
/* select all drives (thus, switch them off) */
  ciab.ciaprb&=~(CIAF_DSKSEL0|CIAF_DSKSEL1|CIAF_DSKSEL2|CIAF_DSKSEL3);
/* deselect drives again (well, why not?) 	*/
  ciab.ciaprb|=CIAF_DSKSEL0|CIAF_DSKSEL1|CIAF_DSKSEL2|CIAF_DSKSEL3;

  sub(sub_dst,ql_lomem,ql_himem,rom_dst,qp,
		rom[0].rlen,rom_len,rom[1].rlen,ql_ssp,qldate);
}

