unit TarTestFixture;

interface

uses
  LibTar,
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework;

type
  [TestFixture]
  TMyTestObject = class
  private
    FMemoryStream : TMemoryStream;
    FTarWriter : TTarWriter;
    FTarArchive : TTarArchive;

  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure Test1;
    [Test]
    procedure Test2;
    [Test]
    procedure Test3;
    // Test with TestCase Attribute to supply parameters.
  end;

implementation

procedure TMyTestObject.Setup;
begin
  FMemoryStream := TMemoryStream.Create;
  FTarWriter := TTarWriter.Create(FMemoryStream);
end;

procedure TMyTestObject.TearDown;
begin
  FreeAndNil(FTarWriter);
  FreeAndNil(FMemoryStream);
end;

procedure TMyTestObject.Test1;
var
  i: Integer;
begin
  for i := 0 to 100 do
  begin
    FTarWriter.AddString(AnsiString('adsfadfadfdsfdsaf'), AnsiString('test' + i.ToString), now - 1001 + i);
  end;
  FMemoryStream.SaveToFile('test.tar');
end;

procedure TMyTestObject.Test2;
var
  i: Integer;
  dirRec : TTarDirRec;
begin
  FMemoryStream.Position := 0;
  FMemoryStream.LoadFromFile('test.tar');
  FTarArchive := TTarArchive.Create(FMemoryStream);
  FTarArchive.Reset;
  i := 0;
  while FTarArchive.FindNext(dirRec) do
  begin
    Inc(i);
  end;
  Assert.AreEqual(101, i, 'Filecount does not match');
end;

procedure TMyTestObject.Test3;
var
  i: Integer;
  dirRec : TTarDirRec;
  fs : TFileStream;
begin
// Note this uses a file on my hard disk which you wont have.  Just comment out this test
  fs := TFileStream.Create('D:\Programming\Containers\mail1_2022-12-01_00-05.tar', fmOpenRead);
  FTarArchive := TTarArchive.Create(fs);
  FTarArchive.Reset;
  i := 0;
  while FTarArchive.FindNext(dirRec) do
  begin
    Inc(i);
  end;
  Assert.AreEqual(357671, i, 'Filecount does not match');
end;

initialization
  TDUnitX.RegisterTestFixture(TMyTestObject);

end.
