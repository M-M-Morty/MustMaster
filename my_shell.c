//unix/linux系统环境下


#include <stdio.h>
#include <unistd.h>
#include <wait.h>
#include <stdlib.h>
#include <string.h>
#define MAX 128

void eval(char *cmdline);
int parseline(char *buf,char **argv);
int builtin_command(char **argv);

int main()
{
    char cmdline[MAX];

    while (1)
    {
        printf("myshell$ ");
        fgets(cmdline,MAX,stdin);
        if(feof(stdin))
        {
            printf("error");
            exit(0);
        }
        eval(cmdline);
    }
}

void eval(char *cmdline)
{
    char *argv[MAX];
    char buf[MAX];
    int bg;
    pid_t pid;

    strcpy(buf,cmdline);
    bg=parseline(buf,argv);
    if(argv[0]==NULL)return;
    if(!builtin_command(argv))
    {
        if((pid=fork())==0)
        {
            if(execvp(argv[0],argv)<0)
            {
                printf("%s:Command not found.\n",argv[0]);
                exit(0);
            }
        }
    

        if(!bg)
        {
            int status;
            if(waitpid(-1,&status,0)<0) printf("waitfg:waitpid:error!");
        }
        else printf("%d %s",pid,cmdline);
        
        return;
    }
}

int builtin_command(char **argv)
{
    if(!strcmp(argv[0],"quit")) exit(0);
    if(!strcmp(argv[0],"&")) return 1;
    return 0;
}

int parseline(char *buf,char **argv)
{
    char *delim;
    int argc;
    int bg;

    buf[strlen(buf)-1]=' ';
    while(*buf&&(*buf==' '))//忽略最前面的空字符
        buf++;

    argc=0;
    while((delim=strchr(buf,' ')))
    {
        argv[argc++]=buf;
        *delim='\0';
        buf=delim+1;
        while(*buf&&(*buf==' '))
            buf++;
    }

    argv[argc]=NULL;
    if(argc==0)
        return 1;
    if((bg=(*argv[argc-1]=='&'))!=0) argv[--argc]=NULL;

    return bg;
}