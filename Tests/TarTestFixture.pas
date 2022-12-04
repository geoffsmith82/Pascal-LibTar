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
    TA         : TTarArchive;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure Test1;
    [Test]
    procedure Test2;
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
    FTarWriter.AddString('adsfadfadfdsfdsaf', 'test' + i.ToString, now);
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
  TA := TTarArchive.Create(FMemoryStream);
  TA.Reset;
  i := 0;
  while TA.FindNext(dirRec) do
  begin
    Inc(i);
  end;
  Assert.AreEqual(101, i, 'Filecount does not match');

end;

initialization
  TDUnitX.RegisterTestFixture(TMyTestObject);

end.
