(**
===============================================================================================
Name    : LibTar
===============================================================================================
Subject : Handling of "tar" files
===============================================================================================
Author  : Stefan Heymann
          Eschenweg 3
          72076 Tübingen
          GERMANY

E-Mail:   stefan@destructor.de
Web:      www.destructor.de

===============================================================================================
TTarArchive Usage
-----------------
- Choose a constructor
- Make an instance of TTarArchive                  TA := TTarArchive.Create (Filename);
- Scan through the archive                         TA.Reset;
                                                   while TA.FindNext (DirRec) do begin
- Evaluate the DirRec for each file                  ListBox.Items.Add (DirRec.Name);
- Read out the current file                          TA.ReadFile (DestFilename);
  (You can ommit this if you want to
  read in the directory only)                        end;
- You're done                                      TA.Free;


TTarWriter Usage
----------------
- Choose a constructor
- Make an instance of TTarWriter                   TW := TTarWriter.Create ('my.tar');
- Add a file to the tar archive                    TW.AddFile ('foobar.txt');
- Add a string as a file                           TW.AddString (SL.Text, 'joe.txt', Now);
- Destroy TarWriter instance                       TW.Free;
- Now your tar file is ready.


Source, Legals ("Licence")
--------------------------
The official site to get this code is http://www.destructor.de/

Usage and Distribution of this Source Code is ruled by the
"Destructor.de Source code Licence" (DSL) which comes with this file or
can be downloaded at http://www.destructor.de/

IN SHORT: Usage and distribution of this source code is free.
          You use it completely on your own risk.
===============================================================================================
!!!  All parts of this code which are not finished or known to be buggy
     are marked with three exclamation marks
===============================================================================================
Date        Author Changes
-----------------------------------------------------------------------------------------------
2001-04-26  HeySt  0.0.1 Start
2001-04-28  HeySt  1.0.0 First Release
2001-06-19  HeySt  2.0.0 Finished TTarWriter
2001-09-06  HeySt  2.0.1 Bugfix in TTarArchive.FindNext: FBytesToGo must sometimes be 0
2001-10-25  HeySt  2.0.2 Introduced the ClearDirRec procedure
2001-11-13  HeySt  2.0.3 Bugfix: Take out ClearDirRec call from WriteTarHeader
                         Bug Reported by Tony BenBrahim
2001-12-25  HeySt  2.0.4 WriteTarHeader: Fill Rec with zero bytes before filling it
2002-05-18  HeySt  2.0.5 Kylix awareness: Thanks to Kerry L. Davison for the changes
2005-09-03  HeySt  2.0.6 TTarArchive.FindNext: Don't access SourceStream.Size
                         (for compressed streams, which don't know their .Size)
2006-03-13  HeySt  2.0.7 Bugfix in ReadFile (Buffer : POINTER)
2007-05-16  HeySt  2.0.8 Bugfix in TTarWriter.AddFile (Convertfilename in the ELSE branch)
                         Bug Reported by Chris Rorden
2010-11-29  HeySt  2.1.0 WriteTarHeader: Mode values for ftNormal/ftLink/ftSymbolicLink/ftDirectory
                         Thanks to Iouri Kharon for the fix.
                         Still no support for filenames > 100 bytes. Sorry.
                         Support for Unicode Delphi versions (2009, 2010, XE, etc.)
2011-05-23  HeySt  2.1.1 New IFDEF WIN32 in the USES clause
2014-06-23  HeySt  2.1.2 64-Bit Seek operations, CurFilePos as Int64
                         Thanks to Andódy Csaba for the fixes.
*)

unit LibTar;

interface

uses
(*$IFDEF LINUX*)
   Libc,
(*$ENDIF *)
{$IFDEF WIN32}
  {$DEFINE MSWINDOWS} // predefined for D6+/BCB6+    // because in Delphi 5  MSWINDOWS is not defined
{$ENDIF}
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  AnsiStrings,
  System.SysUtils,
  System.Classes;

type
  (*$IFNDEF UNICODE *)
  RawByteString = AnsiString;
  (*$ENDIF *)

  // --- File Access Permissions
  TTarPermission  = (tpReadByOwner, tpWriteByOwner, tpExecuteByOwner,
                     tpReadByGroup, tpWriteByGroup, tpExecuteByGroup,
                     tpReadByOther, tpWriteByOther, tpExecuteByOther);
  TTarPermissions = set of TTarPermission;

  // --- Type of File
  TFileType = (ftNormal,          // Regular file
               ftLink,            // Link to another, previously archived, file (LinkName)
               ftSymbolicLink,    // Symbolic link to another file              (LinkName)
               ftCharacter,       // Character special files
               ftBlock,           // Block special files
               ftDirectory,       // Directory entry. Size is zero (unlimited) or max. number of bytes
               ftFifo,            // FIFO special file. No data stored in the archive.
               ftContiguous,      // Contiguous file, if supported by OS
               ftDumpDir,         // List of files
               ftMultiVolume,     // Multi-volume file part
               ftVolumeHeader);   // Volume header. Can appear only as first record in the archive

  // --- Mode
  TTarMode  = (tmSetUid, tmSetGid, tmSaveText);
  TTarModes = set of TTarMode;

  // --- Record for a Directory Entry
  //     Adjust the ClearDirRec procedure when this record changes!
  TTarDirRec  = record
    Name        : AnsiString;        // File path and name
    Size        : Int64;             // File size in Bytes
    DateTime    : TDateTime;         // Last modification date and time
    Permissions : TTarPermissions;   // Access permissions
    FileType    : TFileType;         // Type of file
    LinkName    : AnsiString;        // Name of linked file (for ftLink, ftSymbolicLink)
    UID         : Integer;           // User ID
    GID         : Integer;           // Group ID
    UserName    : AnsiString;        // User name
    GroupName   : AnsiString;        // Group name
    ChecksumOK  : Boolean;           // Checksum was OK
    Mode        : TTarModes;         // Mode
    Magic       : AnsiString;        // Contents of the "Magic" field
    MajorDevNo  : Integer;           // Major Device No. for ftCharacter and ftBlock
    MinorDevNo  : Integer;           // Minor Device No. for ftCharacter and ftBlock
    FilePos     : Int64;             // Position in TAR file
  end;

  // --- The TAR Archive CLASS
  TTarArchive = class
  protected
    FStream     : TStream;   // Internal Stream
    FOwnsStream : Boolean;   // True if FStream is owned by the TTarArchive instance
    FBytesToGo  : Int64;     // Bytes until the next Header Record
  public
    constructor Create (Stream   : TStream); overload;
    constructor Create (const Filename : string;
                      FileMode : WORD = fmOpenRead OR fmShareDenyWrite); overload;
    destructor Destroy; override;
    /// <summary>
    /// Reset TAR File Pointer
    /// </summary>
    procedure Reset;                                         // Reset File Pointer
    /// <summary>
    /// Reads next Directory Info Record
    /// The Stream pointer must point to the first byte of the tar header
    /// <returns>FALSE if EOF reached</returns>
    /// </summary>
    function  FindNext (var DirRec : TTarDirRec) : Boolean;  // Reads next Directory Info Record. FALSE if EOF reached
    procedure ReadFile (Buffer   : POINTER); overload;       // Reads file data for last Directory Record
    procedure ReadFile (Stream   : TStream); overload;       // -;-
    procedure ReadFile (const Filename : string);  overload;       // -;-
    function  ReadFile : RawByteString;      overload;       // -;-

    procedure GetFilePos (var Current, Size : Int64);        // Current File Position
    procedure SetFilePos (NewPos : Int64);                   // Set new Current File Position
  end;

  // --- The TAR Archive Writer CLASS
  TTarWriter = class
  protected
    FStream      : TStream;
    FOwnsStream  : Boolean;
    FFinalized   : Boolean;
                                   // --- Used at the next "Add" method call: ---
    FPermissions : TTarPermissions;   // Access permissions
    FUID         : Integer;           // User ID
    FGID         : Integer;           // Group ID
    FUserName    : AnsiString;        // User name
    FGroupName   : AnsiString;        // Group name
    FMode        : TTarModes;         // Mode
    FMagic       : AnsiString;        // Contents of the "Magic" field
    constructor CreateEmpty;
    procedure Finalize;
  public
    constructor Create (TargetStream   : TStream); overload;
    constructor Create (const TargetFilename : string; Mode : integer = fmCreate); overload;
    destructor Destroy; override;                   // Writes End-Of-File Tag
    procedure AddFile   (const Filename : string;        TarFilename : AnsiString = '');
    procedure AddStream (Stream   : TStream; const TarFilename : AnsiString; FileDateGmt : TDateTime);
    procedure AddString (Contents : RawByteString; const TarFilename : AnsiString; FileDateGmt : TDateTime);
    procedure AddDir(const Dirname : AnsiString; DateGmt : TDateTime; MaxDirSize : Int64 = 0);
    procedure AddSymbolicLink (const Filename, Linkname : AnsiString; DateGmt : TDateTime);
    procedure AddLink         (const Filename, Linkname : AnsiString; DateGmt : TDateTime);
    procedure AddVolumeHeader (const VolumeId : AnsiString; DateGmt : TDateTime);
  published
    property Permissions : TTarPermissions READ FPermissions WRITE FPermissions;   // Access permissions
    property UID         : Integer         READ FUID         WRITE FUID;           // User ID
    property GID         : Integer         READ FGID         WRITE FGID;           // Group ID
    property UserName    : AnsiString      READ FUserName    WRITE FUserName;      // User name
    property GroupName   : AnsiString      READ FGroupName   WRITE FGroupName;     // Group name
    property Mode        : TTarModes       READ FMode        WRITE FMode;          // Mode
    property Magic       : AnsiString      READ FMagic       WRITE FMagic;         // Contents of the "Magic" field
  end;

// --- Some useful constants
const
  FILETYPE_NAME : array [TFileType] of string =
                  ('Regular', 'Link', 'Symbolic Link', 'Char File', 'Block File',
                   'Directory', 'FIFO File', 'Contiguous', 'Dir Dump', 'Multivol', 'Volume Header');

  ALL_PERMISSIONS     = [tpReadByOwner, tpWriteByOwner, tpExecuteByOwner,
                         tpReadByGroup, tpWriteByGroup, tpExecuteByGroup,
                         tpReadByOther, tpWriteByOther, tpExecuteByOther];
  READ_PERMISSIONS    = [tpReadByOwner, tpReadByGroup,  tpReadByOther];
  WRITE_PERMISSIONS   = [tpWriteByOwner, tpWriteByGroup, tpWriteByOther];
  EXECUTE_PERMISSIONS = [tpExecuteByOwner, tpExecuteByGroup, tpExecuteByOther];


function  PermissionString      (Permissions : TTarPermissions) : string;
function  ConvertFilename       (const Filename : string) : string;
/// <summary>Returns the Date and Time of the last modification of the given File
/// The Result is zero if the file could not be found
/// The Result is given in UTC (GMT) time zone</summary>
function  FileTimeGMT           (const FileName : string) : TDateTime;  overload;
function  FileTimeGMT           (SearchRec   : TSearchRec)      : TDateTime;  overload;
/// <summary>This is included because a FillChar (DirRec, SizeOf (DirRec), 0)
/// will destroy the long string pointers, leading to strange bugs</summary>
procedure ClearDirRec           (var DirRec  : TTarDirRec);


(*
===============================================================================================
IMPLEMENTATION
===============================================================================================
*)

implementation

function PermissionString (Permissions : TTarPermissions) : string;
begin
  Result := '';
  if tpReadByOwner    IN Permissions then Result := Result + 'r' else Result := Result + '-';
  if tpWriteByOwner   IN Permissions then Result := Result + 'w' else Result := Result + '-';
  if tpExecuteByOwner IN Permissions then Result := Result + 'x' else Result := Result + '-';
  if tpReadByGroup    IN Permissions then Result := Result + 'r' else Result := Result + '-';
  if tpWriteByGroup   IN Permissions then Result := Result + 'w' else Result := Result + '-';
  if tpExecuteByGroup IN Permissions then Result := Result + 'x' else Result := Result + '-';
  if tpReadByOther    IN Permissions then Result := Result + 'r' else Result := Result + '-';
  if tpWriteByOther   IN Permissions then Result := Result + 'w' else Result := Result + '-';
  if tpExecuteByOther IN Permissions then Result := Result + 'x' else Result := Result + '-';
end;


function ConvertFilename  (const Filename : string) : string;
         // Converts the filename to Unix conventions
begin
  (*$IFDEF LINUX *)
  Result := Filename;
  (*$ELSE *)
  Result := StringReplace (Filename, '\', '/', [rfReplaceAll]);
  (*$ENDIF *)
end;


function FileTimeGMT (const FileName: string): TDateTime;
         // Returns the Date and Time of the last modification of the given File
         // The Result is zero if the file could not be found
         // The Result is given in UTC (GMT) time zone
var
  SR : TSearchRec;
begin
  Result := 0.0;
  if FindFirst (FileName, faAnyFile, SR) = 0 then
    Result := FileTimeGMT (SR);
  FindClose (SR);
end;


function FileTimeGMT (SearchRec : TSearchRec) : TDateTime;
(*$IFDEF MSWINDOWS *)
var
  SystemFileTime: TSystemTime;
(*$ENDIF *)
(*$IFDEF LINUX *)
var
  TimeVal  : TTimeVal;
  TimeZone : TTimeZone;
(*$ENDIF *)
begin
  Result := 0.0;
  (*$IFDEF MSWINDOWS *) (*$WARNINGS OFF *)
    if (SearchRec.FindData.dwFileAttributes AND faDirectory) = 0 then
      if FileTimeToSystemTime (SearchRec.FindData.ftLastWriteTime, SystemFileTime) then
        Result := EncodeDate (SystemFileTime.wYear, SystemFileTime.wMonth, SystemFileTime.wDay)
                + EncodeTime (SystemFileTime.wHour, SystemFileTime.wMinute, SystemFileTime.wSecond, SystemFileTime.wMilliseconds);
  (*$ENDIF *) (*$WARNINGS ON *)
  (*$IFDEF LINUX *)
     if SearchRec.Attr AND faDirectory = 0 then begin
       Result := FileDateToDateTime (SearchRec.Time);
       GetTimeOfDay (TimeVal, TimeZone);
       Result := Result + TimeZone.tz_minuteswest / (60 * 24);
       end;
  (*$ENDIF *)
end;


procedure ClearDirRec (var DirRec : TTarDirRec);
          // This is included because a FillChar (DirRec, SizeOf (DirRec), 0)
          // will destroy the long string pointers, leading to strange bugs
begin
  WITH DirRec do begin
    Name        := '';
    Size        := 0;
    DateTime    := 0.0;
    Permissions := [];
    FileType    := TFileType (0);
    LinkName    := '';
    UID         := 0;
    GID         := 0;
    UserName    := '';
    GroupName   := '';
    ChecksumOK  := FALSE;
    Mode        := [];
    Magic       := '';
    MajorDevNo  := 0;
    MinorDevNo  := 0;
    FilePos     := 0;
  end;
end;

(*
===============================================================================================
TAR format
===============================================================================================
*)

const
  RECORDSIZE = 512;
  NAMSIZ     = 100;
  TUNMLEN    =  32;
  TGNMLEN    =  32;
  CHKBLANKS  = #32#32#32#32#32#32#32#32;

type
  TTarHeader = packed record
    Name     : array [0..NAMSIZ-1] of AnsiChar;
    Mode     : array [0..7]  of AnsiChar;
    UID      : array [0..7]  of AnsiChar;
    GID      : array [0..7]  of AnsiChar;
    Size     : array [0..11] of AnsiChar;
    MTime    : array [0..11] of AnsiChar;
    ChkSum   : array [0..7]  of AnsiChar;
    LinkFlag : AnsiChar;
    LinkName : array [0..NAMSIZ-1] of AnsiChar;
    Magic    : array [0..7] of AnsiChar;
    UName    : array [0..TUNMLEN-1] of AnsiChar;
    GName    : array [0..TGNMLEN-1] of AnsiChar;
    DevMajor : array [0..7] of AnsiChar;
    DevMinor : array [0..7] of AnsiChar;
  end;

function ExtractText (P : PAnsiChar) : AnsiString;
begin
  Result := AnsiString (P);
end;


function ExtractNumber (P : PAnsiChar) : Integer; overload;
var
  Strg : AnsiString;
begin
  Strg := AnsiString (Trim (string (P)));
  P := PAnsiChar (Strg);
  Result := 0;
  while (P^ <> #32) AND (P^ <> #0) do
  begin
    Result := (ORD (P^) - ORD ('0')) OR (Result SHL 3);
    Inc (P);
  end;
end;


function ExtractNumber64 (P : PAnsiChar) : Int64; overload;
var
  Strg : AnsiString;
begin
  Strg := AnsiString (Trim (string (P)));
  P := PAnsiChar (Strg);
  Result := 0;
  while (P^ <> #32) AND (P^ <> #0) do
  begin
    Result := (ORD (P^) - ORD ('0')) OR (Result SHL 3);
    Inc (P);
  end;
end;



function ExtractNumber (P : PAnsiChar; MaxLen : Integer) : Integer; overload;
var
  S0   : array [0..255] of AnsiChar;
  Strg : AnsiString;
begin
  AnsiStrings.StrLCopy (S0, P, MaxLen);
  Strg := AnsiString (Trim (string (S0)));
  P := PAnsiChar (Strg);
  Result := 0;
  while (P^ <> #32) AND (P^ <> #0) do
  begin
    Result := (ORD (P^) - ORD ('0')) OR (Result SHL 3);
    Inc (P);
  end;
end;


function ExtractNumber64 (P : PAnsiChar; MaxLen : Integer) : Int64; overload;
var
  S0   : array [0..255] of AnsiChar;
  Strg : AnsiString;
begin
  AnsiStrings.StrLCopy (S0, P, MaxLen);
  Strg := AnsiString (Trim (string (S0)));
  P := PAnsiChar (Strg);
  Result := 0;
  while (P^ <> #32) AND (P^ <> #0) do
  begin
    Result := (ORD (P^) - ORD ('0')) OR (Result SHL 3);
    Inc (P);
  end;
end;


function Records (Bytes : Int64) : Int64;
begin
  Result := Bytes DIV RECORDSIZE;
  if Bytes MOD RECORDSIZE > 0 then
    Inc (Result);
end;


procedure Octal (N : Integer; P : PAnsiChar; Len : Integer);
         // Makes a string of octal digits
         // The string will always be "Len" characters long
var
  I : Integer;
begin
  for I := Len-2 downto 0 do
  begin
    (P+I)^ := AnsiChar (ORD ('0') + ORD (N AND $07));
    N := N SHR 3;
  end;
  for I := 0 TO Len-3 do
    if (P+I)^ = '0' then
      (P+I)^ := #32
    else BREAK;
  (P+Len-1)^ := #32;
end;


procedure Octal64 (N : Int64; P : PAnsiChar; Len : Integer);
         // Makes a string of octal digits
         // The string will always be "Len" characters long
var
  I     : Integer;
begin
  for I := Len-2 downto 0 do
  begin
    (P+I)^ := AnsiChar (ORD ('0') + ORD (N AND $07));
    N := N SHR 3;
  end;
  for I := 0 to Len-3 do
    if (P+I)^ = '0' then
      (P+I)^ := #32
    else BREAK;
  (P+Len-1)^ := #32;
end;


procedure OctalN (N : Integer; P : PAnsiChar; Len : Integer);
begin
  Octal (N, P, Len-1);
  (P+Len-1)^ := #0;
end;


procedure WriteTarHeader (Dest : TStream; DirRec : TTarDirRec);
var
  Rec      : array [0..RECORDSIZE-1] of AnsiChar;
  TH       : TTarHeader ABSOLUTE Rec;
  Mode     : Integer;
  NullDate : TDateTime;
  Checksum : CARDINAL;
  I        : Integer;
begin
  FillChar (Rec, RECORDSIZE, 0);
  AnsiStrings.StrLCopy (TH.Name, PAnsiChar (DirRec.Name), NAMSIZ);
  case DirRec.FileType of
    ftNormal, ftLink  : Mode := $08000;
    ftSymbolicLink    : Mode := $0A000;
    ftDirectory       : Mode := $04000;
  else                  Mode := 0;
  end;

  if tmSaveText IN DirRec.Mode then Mode := Mode OR $0200;
  if tmSetGid   IN DirRec.Mode then Mode := Mode OR $0400;
  if tmSetUid   IN DirRec.Mode then Mode := Mode OR $0800;
  if tpReadByOwner    IN DirRec.Permissions then Mode := Mode OR $0100;
  if tpWriteByOwner   IN DirRec.Permissions then Mode := Mode OR $0080;
  if tpExecuteByOwner IN DirRec.Permissions then Mode := Mode OR $0040;
  if tpReadByGroup    IN DirRec.Permissions then Mode := Mode OR $0020;
  if tpWriteByGroup   IN DirRec.Permissions then Mode := Mode OR $0010;
  if tpExecuteByGroup IN DirRec.Permissions then Mode := Mode OR $0008;
  if tpReadByOther    IN DirRec.Permissions then Mode := Mode OR $0004;
  if tpWriteByOther   IN DirRec.Permissions then Mode := Mode OR $0002;
  if tpExecuteByOther IN DirRec.Permissions then Mode := Mode OR $0001;
  OctalN (Mode, @TH.Mode, 8);
  OctalN (DirRec.UID, @TH.UID, 8);
  OctalN (DirRec.GID, @TH.GID, 8);
  Octal64 (DirRec.Size, @TH.Size, 12);
  NullDate := EncodeDate (1970, 1, 1);
  if DirRec.DateTime >= NullDate then
    Octal (Trunc ((DirRec.DateTime - NullDate) * 86400.0), @TH.MTime, 12)
  else
    Octal (Trunc (                   NullDate  * 86400.0), @TH.MTime, 12);

  case DirRec.FileType of
    ftNormal       : TH.LinkFlag := '0';
    ftLink         : TH.LinkFlag := '1';
    ftSymbolicLink : TH.LinkFlag := '2';
    ftCharacter    : TH.LinkFlag := '3';
    ftBlock        : TH.LinkFlag := '4';
    ftDirectory    : TH.LinkFlag := '5';
    ftFifo         : TH.LinkFlag := '6';
    ftContiguous   : TH.LinkFlag := '7';
    ftDumpDir      : TH.LinkFlag := 'D';
    ftMultiVolume  : TH.LinkFlag := 'M';
    ftVolumeHeader : TH.LinkFlag := 'V';
  end;
  AnsiStrings.StrLCopy (TH.LinkName, PAnsiChar (DirRec.LinkName), NAMSIZ);
  AnsiStrings.StrLCopy (TH.Magic, PAnsiChar (DirRec.Magic + #32#32#32#32#32#32#32#32), 8);
  AnsiStrings.StrLCopy (TH.UName, PAnsiChar (DirRec.UserName), TUNMLEN);
  AnsiStrings.StrLCopy (TH.GName, PAnsiChar (DirRec.GroupName), TGNMLEN);
  OctalN (DirRec.MajorDevNo, @TH.DevMajor, 8);
  OctalN (DirRec.MinorDevNo, @TH.DevMinor, 8);
  AnsiStrings.StrMove (TH.ChkSum, CHKBLANKS, 8);

  CheckSum := 0;
  for I := 0 to SizeOf (TTarHeader)-1 do
    Inc (CheckSum, Integer (ORD (Rec [I])));
  OctalN (CheckSum, @TH.ChkSum, 8);

  Dest.Write (TH, RECORDSIZE);
end;


(*
===============================================================================================
TTarArchive
===============================================================================================
*)

constructor TTarArchive.Create (Stream : TStream);
begin
  inherited Create;
  FStream     := Stream;
  FOwnsStream := FALSE;
  Reset;
end;


constructor TTarArchive.Create (const Filename : string; FileMode : WORD);
begin
  inherited Create;
  FStream     := TFileStream.Create (Filename, FileMode);
  FOwnsStream := TRUE;
  Reset;
end;


destructor TTarArchive.Destroy;
begin
  if FOwnsStream then
    FStream.Free;
  inherited Destroy;
end;


procedure TTarArchive.Reset;
          // Reset File Pointer
begin
  FStream.Position := 0;
  FBytesToGo       := 0;
end;


function  TTarArchive.FindNext (var DirRec : TTarDirRec) : Boolean;
          // Reads next Directory Info Record
          // The Stream pointer must point to the first byte of the tar header
var
  Rec          : array [0..RECORDSIZE-1] of CHAR;
  CurFilePos   : Int64;
  Header       : TTarHeader ABSOLUTE Rec;
  I            : Integer;
  HeaderChkSum : WORD;
  Checksum     : CARDINAL;
begin
  // --- Scan until next pointer
  if FBytesToGo > 0 then
    FStream.Seek (Records (FBytesToGo) * RECORDSIZE, soCurrent);

  // --- EOF reached?
  Result := FALSE;
  CurFilePos := FStream.Position;
  try
    FStream.ReadBuffer (Rec, RECORDSIZE);
    if Rec [0] = #0 then EXIT;   // EOF reached
  except
    EXIT;   // EOF reached, too
  end;
  Result := TRUE;

  ClearDirRec (DirRec);

  DirRec.FilePos := CurFilePos;
  DirRec.Name := ExtractText (Header.Name);
  DirRec.Size := ExtractNumber64 (@Header.Size, 12);
  DirRec.DateTime := EncodeDate (1970, 1, 1) + (ExtractNumber (@Header.MTime, 12) / 86400.0);
  I := ExtractNumber (@Header.Mode);
  if I AND $0100 <> 0 then Include (DirRec.Permissions, tpReadByOwner);
  if I AND $0080 <> 0 then Include (DirRec.Permissions, tpWriteByOwner);
  if I AND $0040 <> 0 then Include (DirRec.Permissions, tpExecuteByOwner);
  if I AND $0020 <> 0 then Include (DirRec.Permissions, tpReadByGroup);
  if I AND $0010 <> 0 then Include (DirRec.Permissions, tpWriteByGroup);
  if I AND $0008 <> 0 then Include (DirRec.Permissions, tpExecuteByGroup);
  if I AND $0004 <> 0 then Include (DirRec.Permissions, tpReadByOther);
  if I AND $0002 <> 0 then Include (DirRec.Permissions, tpWriteByOther);
  if I AND $0001 <> 0 then Include (DirRec.Permissions, tpExecuteByOther);
  if I AND $0200 <> 0 then Include (DirRec.Mode, tmSaveText);
  if I AND $0400 <> 0 then Include (DirRec.Mode, tmSetGid);
  if I AND $0800 <> 0 then Include (DirRec.Mode, tmSetUid);
  case Header.LinkFlag of
    #0, '0' : DirRec.FileType := ftNormal;
    '1'     : DirRec.FileType := ftLink;
    '2'     : DirRec.FileType := ftSymbolicLink;
    '3'     : DirRec.FileType := ftCharacter;
    '4'     : DirRec.FileType := ftBlock;
    '5'     : DirRec.FileType := ftDirectory;
    '6'     : DirRec.FileType := ftFifo;
    '7'     : DirRec.FileType := ftContiguous;
    'D'     : DirRec.FileType := ftDumpDir;
    'M'     : DirRec.FileType := ftMultiVolume;
    'V'     : DirRec.FileType := ftVolumeHeader;
  end;
  DirRec.LinkName   := ExtractText (Header.LinkName);
  DirRec.UID        := ExtractNumber (@Header.UID);
  DirRec.GID        := ExtractNumber (@Header.GID);
  DirRec.UserName   := ExtractText (Header.UName);
  DirRec.GroupName  := ExtractText (Header.GName);
  DirRec.Magic      := AnsiString (Trim (string (Header.Magic)));
  DirRec.MajorDevNo := ExtractNumber (@Header.DevMajor);
  DirRec.MinorDevNo := ExtractNumber (@Header.DevMinor);

  HeaderChkSum := ExtractNumber (@Header.ChkSum);   // Calc Checksum
  CheckSum := 0;
  AnsiStrings.StrMove (Header.ChkSum, CHKBLANKS, 8);
  for I := 0 to SizeOf (TTarHeader)-1 do
    Inc (CheckSum, Integer (ORD (Rec [I])));
  DirRec.CheckSumOK := WORD (CheckSum) = WORD (HeaderChkSum);

  if DirRec.FileType in [ftLink, ftSymbolicLink, ftDirectory, ftFifo, ftVolumeHeader]
    then FBytesToGo := 0
    else FBytesToGo := DirRec.Size;
end;


procedure TTarArchive.ReadFile (Buffer : POINTER);
          // Reads file data for the last Directory Record. The entire file is read into the buffer.
          // The buffer must be large enough to take up the whole file.
var
  RestBytes : Integer;
begin
  if FBytesToGo = 0 then EXIT;
  RestBytes := Records (FBytesToGo) * RECORDSIZE - FBytesToGo;
  FStream.ReadBuffer (Buffer^, FBytesToGo);
  FStream.Seek (RestBytes, soCurrent);
  FBytesToGo := 0;
end;


procedure TTarArchive.ReadFile (Stream : TStream);
          // Reads file data for the last Directory Record.
          // The entire file is written out to the stream.
          // The stream is left at its current position prior to writing
var
  RestBytes : Integer;
begin
  if FBytesToGo = 0 then EXIT;
  RestBytes := Records (FBytesToGo) * RECORDSIZE - FBytesToGo;
  Stream.CopyFrom (FStream, FBytesToGo);
  FStream.Seek (RestBytes, soCurrent);
  FBytesToGo := 0;
end;


procedure TTarArchive.ReadFile (const Filename : string);
          // Reads file data for the last Directory Record.
          // The entire file is saved in the given Filename
var
  FS : TFileStream;
begin
  FS := TFileStream.Create (Filename, fmCreate);
  try
    ReadFile (FS);
  finally
    FS.Free;
  end;
end;


function  TTarArchive.ReadFile : RawByteString;
          // Reads file data for the last Directory Record. The entire file is returned
          // as a large ANSI string.
var
  RestBytes : Integer;
begin
  if FBytesToGo = 0 then EXIT;
  RestBytes := Records (FBytesToGo) * RECORDSIZE - FBytesToGo;
  SetLength (Result, FBytesToGo);
  FStream.ReadBuffer (PAnsiChar (Result)^, FBytesToGo);
  FStream.Seek (RestBytes, soCurrent);
  FBytesToGo := 0;
end;


procedure TTarArchive.GetFilePos (var Current, Size : Int64);
          // Returns the Current Position in the TAR stream
begin
  Current := FStream.Position;
  Size    := FStream.Size;
end;


procedure TTarArchive.SetFilePos (NewPos : Int64);                   // Set new Current File Position
begin
  if NewPos < FStream.Size then
    FStream.Seek (NewPos, soBeginning);
end;


(*
===============================================================================================
TTarWriter
===============================================================================================
*)

CONSTRUCTOR TTarWriter.CreateEmpty;
var
  TP : TTarPermission;
begin
  inherited Create;
  FOwnsStream  := FALSE;
  FFinalized   := FALSE;
  FPermissions := [];
  for TP := Low (TP) to High (TP) do
    Include (FPermissions, TP);
  FUID       := 0;
  FGID       := 0;
  FUserName  := '';
  FGroupName := '';
  FMode      := [];
  FMagic     := 'ustar';
end;

constructor TTarWriter.Create (TargetStream   : TStream);
begin
  CreateEmpty;
  FStream     := TargetStream;
  FOwnsStream := FALSE;
end;


constructor TTarWriter.Create (const TargetFilename : string; Mode : Integer = fmCreate);
begin
  CreateEmpty;
  FStream     := TFileStream.Create (TargetFilename, Mode);
  FOwnsStream := TRUE;
end;


destructor TTarWriter.Destroy;
begin
  if NOT FFinalized then
  begin
    Finalize;
    FFinalized := TRUE;
  end;
  if FOwnsStream then
    FStream.Free;
  inherited Destroy;
end;


procedure TTarWriter.AddFile(const Filename : string;  TarFilename : AnsiString = '');
var
  S    : TFileStream;
  Date : TDateTime;
begin
  Date := FileTimeGMT (Filename);
  if TarFilename = '' then
    TarFilename := AnsiString (ConvertFilename (Filename))
  else
    TarFilename := AnsiString (ConvertFilename (string (TarFilename)));
  S := TFileStream.Create (Filename, fmOpenRead OR fmShareDenyWrite);
  try
    AddStream (S, TarFilename, Date);
  finally
    S.Free;
  end;
end;


procedure TTarWriter.AddStream (Stream : TStream; const TarFilename : AnsiString; FileDateGmt : TDateTime);
var
  DirRec      : TTarDirRec;
  Rec         : array [0..RECORDSIZE-1] of CHAR;
  BytesToRead : Int64;      // Bytes to read from the Source Stream
  BlockSize   : Int64;      // Bytes to write out for the current record
begin
  ClearDirRec (DirRec);
  DirRec.Name        := TarFilename;
  DirRec.Size        := Stream.Size - Stream.Position;
  DirRec.DateTime    := FileDateGmt;
  DirRec.Permissions := FPermissions;
  DirRec.FileType    := ftNormal;
  DirRec.LinkName    := '';
  DirRec.UID         := FUID;
  DirRec.GID         := FGID;
  DirRec.UserName    := FUserName;
  DirRec.GroupName   := FGroupName;
  DirRec.ChecksumOK  := TRUE;
  DirRec.Mode        := FMode;
  DirRec.Magic       := FMagic;
  DirRec.MajorDevNo  := 0;
  DirRec.MinorDevNo  := 0;

  WriteTarHeader (FStream, DirRec);
  BytesToRead := DirRec.Size;
  while BytesToRead > 0 do
  begin
    BlockSize := BytesToRead;
    if BlockSize > RECORDSIZE then BlockSize := RECORDSIZE;
    FillChar (Rec, RECORDSIZE, 0);
    Stream.Read (Rec, BlockSize);
    FStream.Write (Rec, RECORDSIZE);
    DEC (BytesToRead, BlockSize);
  end;
end;


procedure TTarWriter.AddString (Contents : RawByteString; const TarFilename : AnsiString; FileDateGmt : TDateTime);
var
  S : TStringStream;
begin
  S := TStringStream.Create (Contents);
  try
    AddStream (S, TarFilename, FileDateGmt);
  finally
    S.Free;
  end;
end;


procedure TTarWriter.AddDir (const Dirname : AnsiString; DateGmt : TDateTime; MaxDirSize : Int64 = 0);
var
  DirRec      : TTarDirRec;
begin
  ClearDirRec (DirRec);
  DirRec.Name        := Dirname;
  DirRec.Size        := MaxDirSize;
  DirRec.DateTime    := DateGmt;
  DirRec.Permissions := FPermissions;
  DirRec.FileType    := ftDirectory;
  DirRec.LinkName    := '';
  DirRec.UID         := FUID;
  DirRec.GID         := FGID;
  DirRec.UserName    := FUserName;
  DirRec.GroupName   := FGroupName;
  DirRec.ChecksumOK  := TRUE;
  DirRec.Mode        := FMode;
  DirRec.Magic       := FMagic;
  DirRec.MajorDevNo  := 0;
  DirRec.MinorDevNo  := 0;

  WriteTarHeader (FStream, DirRec);
end;


procedure TTarWriter.AddSymbolicLink (const Filename, Linkname : AnsiString; DateGmt : TDateTime);
var
  DirRec : TTarDirRec;
begin
  ClearDirRec (DirRec);
  DirRec.Name        := Filename;
  DirRec.Size        := 0;
  DirRec.DateTime    := DateGmt;
  DirRec.Permissions := FPermissions;
  DirRec.FileType    := ftSymbolicLink;
  DirRec.LinkName    := Linkname;
  DirRec.UID         := FUID;
  DirRec.GID         := FGID;
  DirRec.UserName    := FUserName;
  DirRec.GroupName   := FGroupName;
  DirRec.ChecksumOK  := TRUE;
  DirRec.Mode        := FMode;
  DirRec.Magic       := FMagic;
  DirRec.MajorDevNo  := 0;
  DirRec.MinorDevNo  := 0;

  WriteTarHeader (FStream, DirRec);
end;


procedure TTarWriter.AddLink (const Filename, Linkname : AnsiString; DateGmt : TDateTime);
var
  DirRec : TTarDirRec;
begin
  ClearDirRec (DirRec);
  DirRec.Name        := Filename;
  DirRec.Size        := 0;
  DirRec.DateTime    := DateGmt;
  DirRec.Permissions := FPermissions;
  DirRec.FileType    := ftLink;
  DirRec.LinkName    := Linkname;
  DirRec.UID         := FUID;
  DirRec.GID         := FGID;
  DirRec.UserName    := FUserName;
  DirRec.GroupName   := FGroupName;
  DirRec.ChecksumOK  := TRUE;
  DirRec.Mode        := FMode;
  DirRec.Magic       := FMagic;
  DirRec.MajorDevNo  := 0;
  DirRec.MinorDevNo  := 0;

  WriteTarHeader (FStream, DirRec);
end;


procedure TTarWriter.AddVolumeHeader (const VolumeId : AnsiString; DateGmt : TDateTime);
var
  DirRec : TTarDirRec;
begin
  ClearDirRec (DirRec);
  DirRec.Name        := VolumeId;
  DirRec.Size        := 0;
  DirRec.DateTime    := DateGmt;
  DirRec.Permissions := FPermissions;
  DirRec.FileType    := ftVolumeHeader;
  DirRec.LinkName    := '';
  DirRec.UID         := FUID;
  DirRec.GID         := FGID;
  DirRec.UserName    := FUserName;
  DirRec.GroupName   := FGroupName;
  DirRec.ChecksumOK  := TRUE;
  DirRec.Mode        := FMode;
  DirRec.Magic       := FMagic;
  DirRec.MajorDevNo  := 0;
  DirRec.MinorDevNo  := 0;

  WriteTarHeader (FStream, DirRec);
end;


procedure TTarWriter.Finalize;
          // Writes the End-Of-File Tag
          // Data after this tag will be ignored
          // The destructor calls this automatically if you didn't do it before
var
  Rec : array [0..RECORDSIZE-1] of CHAR;
begin
  FillChar (Rec, SizeOf (Rec), 0);
  FStream.Write (Rec, RECORDSIZE);
  FFinalized := TRUE;
end;


end.

