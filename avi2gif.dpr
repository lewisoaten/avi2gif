program AVI2GIF;

uses
  Forms,
  main in 'main.pas' {Form1},
  FTGifAnimate in 'FTGifAnimate.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'AVI2GIF';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
