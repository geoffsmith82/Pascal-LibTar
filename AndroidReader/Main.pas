unit Main;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  LibTar
  ;

type
  TFrmMain = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
    FTarWriter : TTarWriter;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.fmx}

end.
