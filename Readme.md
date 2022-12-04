
 LibTar

LibTar
======

Native ObjectPascal Library for accessing **tar** (_T_ape _Ar_chive) files

Original Author: Stefan Heymann, E-Mail [stefan@destructor.de](mailto:stefan@destructor.de)

Repository Owner: Geoffrey Smith


Purpose
-------

LibTar is a Library which contains the ObjectPascal class **TTarArchive.** Using this class, you can read the contents (Directory entries and file contents) of a tar file.

#### geoffsmith82
I hope to use the original code of the project and add Unit Tests and improve cross-platform compatibility.  It shouldn't be to hard to make it cross platform compatible.

About _tar_
-----------

tar is a format widely used on Unix and Linux systems. "tar" is short for "Tape Archive". The format was intended primarily for use with tape backup devices. However, tar files are also stored on disks. The common extension for tar files is ".tar".

A tar file contains several files, making one file out of them. There is no compression. The tar file just contains a directory entry for each file (which holds information like the name of the file, size, last modified date, access permissions, etc.). and the file itself.

TTarArchive
-----------

Using the TTarArchive class, you scan through the tar file, thereby reading out the directory entries and – if you want – the files.

|     |     |
| --- | --- |
| **Step** | **Code** |
| **Choose a constructor**<br><br>You can either pass a TStream instance or a filename | constructor Create (Stream : TStream);  overload;<br>constructor Create (Filename : STRING); overload; |
| **Make an instance of TTarArchive** | TA := TTarArchive.Create (Filename); |
| **Prepare your scan** | TA.Reset; |
| **Scan through the archive** | while TA.FindNext (DirRec) do begin |
| **Evaluate the DirRec for each file** | ListBox.Items.Add (DirRec.Name); |
| **Read out the current file**<br><br>You can leave this step out if you don't want to read the file | TA.ReadFile (DestFilename);<br>  END; |
| **You're done** | TA.Free |

FindNext, TTarDirRec
--------------------

The **FindNext** function returns two values:

The function return value (boolean) is true, when there was another file found in the archive and false when the end of the archive has been reached. So you can use it in a "while FindNext () do" loop. Using this loop, you hop from file to file, accessing one at a time.

There is a var parameter, named DirRec of type TTarDirRec. This record gives all the informations about the current file in the archive has the following fields:

 <table border="0" cellpadding="3">
    <tr>
      <td bgcolor="#40C0C0" valign="top" align="left"><font face="Verdana" size="2"><b>Field Name</b></font></td>
      <td bgcolor="#40C0C0" valign="top" align="left"><b><font face="Verdana" size="2">Content</font></b></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font face="Verdana" size="2"><b>Name</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font face="Verdana" size="2">The file's path and file name. The
        path is usually divided with slash characters, because tar is a Unix format</font></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font face="Verdana" size="2"><b>Size</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font face="Verdana" size="2">The size of the file in bytes</font></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font face="Verdana" size="2"><b>DateTime</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font face="Verdana" size="2">Last last modification date and time.
        Note that this time is given in UTC (GMT). You must probably convert it to your local
        time before using it for comparisons.</font></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font face="Verdana" size="2"><b>Permissions</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana">A set telling who had which access
        rights to the file at the time it was written to the archive:</font>
        <div align="left">
          <table border="0" cellpadding="3">
            <tr>
              <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">tpReadByOwner,<br>
                tpWriteByOwner,<br>
                tpExecuteByOwner</font></td>
              <td valign="top" align="left" bgcolor="#C5EBEB"><font face="Verdana" size="2">The file owner has
                permission to read/write/execute it</font></td>
            </tr>
            <tr>
              <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">tpReadByGroup,<br>
 tpWriteByGroup,<br>
                tpExecuteByGroup</font></td>
              <td valign="top" align="left" bgcolor="#C5EBEB"><font face="Verdana" size="2">The user's group has
                permission to read/write/execute the file</font></td>
            </tr>
            <tr>
              <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">                     tpReadByOther,<br>
                tpWriteByOther,<br>
                tpExecuteByOther</font></td>
              <td valign="top" align="left" bgcolor="#C5EBEB"><font face="Verdana" size="2">All other users have
                permission to read/write/execute the file</font></td>
            </tr>
          </table>
        </div>
      </td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font face="Verdana" size="2"><b>FileType</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana">The type of the file:</font>
        <table border="0" cellpadding="3">
          <tr>
            <td valign="top" align="left" bgcolor="#40C0C0"><font size="2" face="Verdana"><b>TFileType</b></font></td>
            <td valign="top" align="left" bgcolor="#40C0C0"><font size="2" face="Verdana"><b>Description</b></font></td>
          </tr>
          <tr>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">ftNormal</font></td>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">A regular file</font></td>
          </tr>
          <tr>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">ftLink</font></td>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">A link to another, previously archived, file. There is no data stored for a
              link. The name of the file which the link refers to is stored in the
              &quot;LinkName&quot; field of TTarDirRec</font></td>
          </tr>
          <tr>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">ftSymbolicLink</font></td>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">A symbolic link to another file. There is no data stored for a link. The name of
              the file which the link refers to is stored in the &quot;LinkName&quot; field of
              TTarDirRec</font></td>
          </tr>
          <tr>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">ftCharacter, ftBlock</font></td>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">Character/Block special files. Unix specific. Can be treated as a regular file
              by other OSes</font></td>
          </tr>
          <tr>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">ftDirectory</font></td>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">A subdirectory entry. There is no data stored for a directory. The
              &quot;Size&quot; field of TTarDirRec is zero (unlimited) or gives the maximum
              number of bytes which may be stored in the directory.</font></td>
          </tr>
          <tr>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">ftFifo</font></td>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">FIFO special file. There is no data stored for a FIFO file.</font></td>
          </tr>
          <tr>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">ftContiguous</font></td>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">If supported by the OS, the file shall be stored in contiguous blocks of the
              storage medium. Otherwise, it can be treated like a regular file.</font></td>
          </tr>
          <tr>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">ftDumpDir</font></td>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">This represents a directory and a list of files created by the -G option of tar.
              The Size field gives the total size of the associated list of files. Each filename
              is preceded by either a 'Y' (meaning the file should be in this archive) or an 'N'
              (The file is a directory, or is not stored in the archive). Each filename is
              terminated by a null. There is an additional null after the last filename.</font></td>
          </tr>
          <tr>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">ftMultivolume</font></td>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">This represents a file continued from another volume of a multi-volume archive
              created with the -M option of tar. The original type of the file is not given
              here. Size field gives the maximum size of this piece of the file (assuming the
              volume does not end before the file is written out). The offset field gives the
              offset from the beginning of the file where this part of the file begins. Thus
              size plus offset should equal the original size of the file.</font></td>
          </tr>
          <tr>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">ftVolumeHeader</font></td>
            <td valign="top" align="left" bgcolor="#C5EBEB"><font size="2" face="Verdana">This file type is used to mark the volume header that was given with
              the -V option when the archive was created. The Name field contains the name given after the
              -V option. The Size field is zero. Only the first file in each volume of an archive should have this type.</font></td>
          </tr>
        </table>
      </td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana"><b>LinkName</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana">If the
        FileType is ftLink or ftSymbolicLink, the LinkName field contains the name of the file
        where the link is going to.</font></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana"><b>UID, GID</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana">Numerical
        User ID and Group ID</font></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana"><b>UserName,
        GroupName</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana">User Name
        and Group Name</font></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana"><b>CheckSumOK</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana">True, if the
        checksum of the tar header was checked OK, false if not.</font></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana"><b>Mode</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana">I don't know
        enough about tar to tell you what the heck this means. Sorry.</font></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana"><b>Magic</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana">Contains the
        string in the &quot;magic&quot; field of the tar header. Possible values are 'ustar' and
        'GNUtar'. If it is 'ustar', then the UserName and GroupName field can be considered
        valid. If it is 'GNUtar' then there is a GNU format dump entry.</font></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana"><b>MajorDevNo,
        MinorDevNo</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana">Major and
        Minor Device Number for Files of type ftCharacter or ftBlock</font></td>
    </tr>
    <tr>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana"><b>FilePos</b></font></td>
      <td bgcolor="#9FDFDF" valign="top" align="left"><font size="2" face="Verdana">The Position
        in the tar file. This corresponds to the byte position of the first byte of the current
        header record. You can use the &quot;SetFilePos&quot; method to return to this position
        at any time later.</font></td>
    </tr>
  </table>

File Position
-------------

There are several methods you can use to retrieve or set the Current Position in the tar file during or after scanning:

* Every _TTarDirRec_ contains a field _FilePos_ which contains the Current Position of the beginning of the corresponding tar header record.
* You can call the _GetFilePos_ method at any time to retrieve the Current Position (Current) and the size (Size) of the whole tar file. Both values are given in bytes. You could use these values for display of a progress bar. The percentage is calculated:  
    `Percent := Current * 100 DIV Size;`
* You can return to a position given by _TTarDirRec.FilePos_ or _GetFilePos_ with the _SetFilePos_ method. After the call to _SetFilePos,_ you must call _FindNext_ to re-read the Directory record entry. After the call to _FindNext,_ you can read the file contents using a call to _ReadFile._

Source, Legals ("Licence")
--------------------------

The official site to get this code is [http://www.destructor.de](http://www.destructor.de)  
  
Usage and Distribution of this Source Code is ruled by the "Destructor.de Source code Licence" (DSL) which comes with this file or can be downloaded at http://www.destructor.de  
  
IN SHORT: Usage and distribution of this source code is free. You use it completely on your own risk.

Support
-------

Please send support requests to [stefan@destructor.de](mailto:stefan@destructor.de). I'll do my best to help you.

Postcardware
------------

If you like this code, please send a postcard of your city to my address (anonymous if you want):

	Stefan Heymann
	Eschenweg 3
	72076 Tübingen
	GERMANY

* * *

2001-04-28, Stefan Heymann
