MODULE TODO;
    FROM ASCII IMPORT NUL;
    FROM Paths IMPORT Locate;
    FROM InOut IMPORT WriteString, WriteLine, WriteLongCard, Read;
    FROM System IMPORT GetEnv, Terminate;
    FROM Strings IMPORT Pos, Append, Length;
    FROM Files IMPORT Open, Close, Write, READ, WRITE, IO, Delete, FileStatus,
                        Create, NORMAL, Seek, SEEKEND;
    FROM SHELL IMPORT Shell;
    FROM XDOS IMPORT BlockReadCreate, BlockReadDestroy, BlockReadLine;
    FROM DATETIME IMPORT GetDate;
    FROM SYSTEM IMPORT ADR;
    FROM FileSpec IMPORT ExtractDirPath;
    FROM Display IMPORT displayAttr, Goto, ClrEOS, DisplayString;
    FROM XString IMPORT RightTrim;
    CONST
        SEMICOLON = ";";
        DATAFILE  = 'TODOLIST.TDL';
        DONEFILE  = 'TODOLIST.TDD';
        TEMPFILE  = 'TODOLIST.$$$';
        SPACE     = 40C;
        BACKSLASH = "\";
        COPYRIGHT = 'TODO v2.0 (c) Copyright Bruce M. Axtens, 1994.';
    VAR
        sTempFile,
        sDoneFile,
        sPath,
        sDataFile : ARRAY [0..63] OF CHAR;
        bFound: BOOLEAN;

    PROCEDURE ExitError( c : CARDINAL);
        BEGIN
        END ExitError;

    PROCEDURE Scan( sDat, sDon, sTmp : ARRAY OF CHAR);
        VAR
            iData,
            iDone,
            iTemp   : INTEGER;
            sShell,
            sLine   : ARRAY [0..254] OF CHAR;
            sTemp   : ARRAY [0..7] OF CHAR;
            cTemp,
            cCnt    : CARDINAL;
            lcLength: LONGCARD;
            xSpace  : CHAR;
            bDirty: BOOLEAN;

        BEGIN
            xSpace := SPACE;
            bDirty := FALSE;
            Open(iData,sDat,READ);
            IF FileStatus # 0 THEN
                ExitError(FileStatus)
            END;
            Create(iTemp,sTmp,NORMAL);
            IF FileStatus # 0 THEN
                ExitError(FileStatus)
            END;
            Open(iDone,sDon,IO);
            IF FileStatus # 0 THEN
                Create(iDone,sDon,NORMAL);
                IF FileStatus # 0 THEN
                    ExitError(FileStatus)
                END;
            END;
            lcLength := 0L;
            Seek(iDone,SEEKEND,lcLength);
            BlockReadCreate( 32767);
            BlockReadLine(iData,sLine,cCnt);
            WHILE cCnt # 0 DO
                IF sLine[0] = "#" THEN
                    bDirty := TRUE;
                    GetDate(sTemp);
                    Write(iDone,ADR(sTemp),SIZE(sTemp),cTemp);
                    Write(iDone,ADR(xSpace),1,cTemp);
                    Write(iDone,ADR(sLine),Length(sLine),cTemp);
                ELSE
                    Write(iTemp,ADR(sLine),Length(sLine),cTemp);
                END;
                BlockReadLine(iData,sLine,cCnt);
            END;
            Close(iData);
            Close(iTemp);
            Close(iDone);
            BlockReadDestroy;
            (*IF bDirty THEN*)
                (* Delete(sDat); *)
                sShell := "SORT <";
                Append(sShell,sTmp);
                Append(sShell," >");
                Append(sShell,sDat);
                WriteLine("Sorting...");
                IF Shell(sShell,cTemp) THEN END;
            (*END;*)
            Delete(sTmp)
        END Scan;

    PROCEDURE ShowData( sDat : ARRAY OF CHAR) : CHAR;
        VAR
            iData : INTEGER;
            sLine : ARRAY [0..79] OF CHAR;
            cLine,
            cCnt  : CARDINAL;
            xChar : CHAR;
        BEGIN
            Goto(0,0);
            ClrEOS;
            Open(iData,sDat,READ);
            IF FileStatus # 0 THEN
                ExitError(FileStatus)
            END;
            cLine := 1;
            displayAttr := 70H;
            DisplayString( COPYRIGHT, 0,0,displayAttr);
            displayAttr := 07H;
            BlockReadCreate(32767);
            BlockReadLine(iData,sLine,cCnt);
            WHILE cCnt # 0 DO
                RightTrim( sLine);
                DisplayString( sLine, cLine,0,displayAttr);
                INC( cLine);
                IF cLine > 23 THEN
                    Goto(0,0);
                    ClrEOS;
                    cLine := 1
                END;
                BlockReadLine(iData,sLine,cCnt);
            END;
            Close(iData);
            BlockReadDestroy;
            Goto(24,0);
            WriteString("E(dit, P(rint, or Q(uit ");
            xChar := 0C;
            WHILE Pos(xChar,"EPQ") > 2 DO
                Read(xChar);
                xChar := CAP(xChar);
            END;
            WriteString(xChar);
            RETURN xChar
        END ShowData;

    PROCEDURE Edit( sDat : ARRAY OF CHAR);
        CONST
            SPACE = 40C;
        VAR
            sEditor,
            sShell : ARRAY [0..127] OF CHAR;
            cCnt  : CARDINAL;
        BEGIN
            GetEnv("TD$ED", sEditor);
            IF sEditor[0] = NUL THEN
                sEditor := "EDIT"
            END;
            sShell := '';
            Append( sShell, sEditor);
            Append( sShell, SPACE);
            Append( sShell, sDat);
            IF Shell( sShell, cCnt) THEN END;
        END Edit;

    PROCEDURE Print( sDat : ARRAY OF CHAR);
        CONST
            SPACE = 40C;
        VAR
            sPrintor,
            sShell : ARRAY [0..127] OF CHAR;
            cCnt  : CARDINAL;
        BEGIN
            GetEnv("TD$PR", sPrintor);
            IF sPrintor[0] = NUL THEN
                sPrintor := "2col"
            END;
            sShell := '';
            Append( sShell, sPrintor);
            Append( sShell, SPACE);
            Append( sShell, sDat);
            IF Shell( sShell, cCnt) THEN END;
        END Print;

    BEGIN
        WriteLine(COPYRIGHT);
        Locate(DATAFILE,"TODO",sDataFile,bFound);
        IF NOT bFound THEN
            Locate(DATAFILE,"PATH",sDataFile,bFound);
            IF NOT bFound THEN
                WriteLine("Error:");
                WriteLine(" The data file TODOLIST.TDL was not found on PATH,");
                WriteLine(" nor was it found through the TODO environment variable.");
                WriteLine("");
                WriteLine(" What to do:");
                WriteLine("  1. The file may not exist. Use a text editor to create it.");
                WriteLine("");
                WriteLine("  2. Modify the PATH to point to the directory containing file.");
                WriteLine("");
                WriteLine("  3. Specify the TODO environment variable to point to the");
                WriteLine("     directory containing the file.");
                WriteLine("");
                Terminate(1)
            END
        END;
        ExtractDirPath(sDataFile,sPath);
        IF sPath[0] = NUL THEN
            sPath := "."
        END;
        sDoneFile := sPath;
        Append(sDoneFile,BACKSLASH);
        Append(sDoneFile,DONEFILE);
        sTempFile := sPath;
        Append(sTempFile,BACKSLASH);
        Append(sTempFile,TEMPFILE);
        LOOP
            Scan( sDataFile, sDoneFile, sTempFile);
            CASE ShowData( sDataFile) OF
                'E' : Edit( sDataFile)
                |
                'P' : Print( sDataFile)
                |
                'Q' : EXIT
            END
        END;
        Terminate(0)


    END TODO.



