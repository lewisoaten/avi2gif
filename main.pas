unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, VFW, ExtCtrls, FTGifAnimate, Ole2, ComCtrls, jpeg; // Shevin: added Ole2 unit

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    Button1: TButton;
    Panel1: TPanel;
    Image1: TImage;
    StatusBar1: TStatusBar;
    ProgressBar1: TProgressBar;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Edit1: TEdit;
    Label1: TLabel;
    Image2: TImage;
    TrackBar1: TTrackBar;
    Button2: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    procedure ShowAvi(FFilename : string);
    procedure LoadAvi(FFilename : string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.Button1Click(Sender: TObject);
begin
if button1.Caption='Reset' then
  begin
  progressbar1.Position:=0;
  panel1.Caption:='Preview...';
  statusbar1.Panels[1].Text:='00:00:00';
  statusbar1.Panels[0].Text:='Ready...';
  button1.Caption:='Load';
  image1.Picture:=image2.Picture;
  exit;
  end;
if button1.Caption='Load' then
  begin
  opendialog1.filename:=paramstr(0);
  opendialog1.Execute;
  LoadAvi(opendialog1.filename);
  trackbar1.SelEnd:=trackbar1.Max;
  trackbar1.Enabled:=true;
  button2.Enabled:=true;
  button3.Enabled:=true;
  button1.Caption:='Start';
  exit;
  end;
if button1.Caption='Start' then
  begin
  button1.Enabled:=false;
  ShowAvi(OpenDialog1.FileName);
  button1.Enabled:=true;
  trackbar1.Enabled:=false;
  button2.Enabled:=false;
  button3.Enabled:=false;
  button1.Caption:='Reset';
  exit;
  end;
end;

procedure TForm1.LoadAvi(FFilename : string);
var
 FrameIndex:  INTEGER;
 pavi:PAVIFile;
 pavis:PAVIStream;
 pavisound:PAVIStream;
 ob:PGetFrame;
 pbmi:PBitmapInfoHeader;
 Punter:PByte;
 han,i:integer;
 Desti:TCanvas;
 microsperframe:integer;
 principio,fin:integer;

   // Shevin: Variables added
   info  : PAVISTREAMINFOA;
   bitmap : TBitmap;
   AviOpen : integer;
   hexcode : string;
   EMsg : string;
   lasterr : integer;
begin
  // Shevin: save return code from AVIFileOpen to determine error msg.
  AviOpen := AVIFIleOpen(pavi,Pchar(FFilename),OF_READ,nil);
  if 0<>AviOpen then
  begin
   case AviOpen of
    AVIERR_UNSUPPORTED  : ShowMessage('UNSUPPORTED');
    AVIERR_BADFORMAT    : ShowMessage('BADFORMAT');
    AVIERR_MEMORY       : ShowMessage('MEMORY');
    AVIERR_INTERNAL     : ShowMessage('INTERNAL');
    AVIERR_BADFLAGS     : ShowMessage('BADFLAGS');
    AVIERR_BADPARAM     : ShowMessage('BADPARM');
    AVIERR_BADSIZE      : ShowMessage('BADSIZE');
    AVIERR_BADHANDLE    : ShowMessage('BADHANDLE');
    AVIERR_FILEREAD     : ShowMessage('FILEREAD');
    AVIERR_FILEWRITE    : ShowMessage('FILEWRITE');
    AVIERR_FILEOPEN     : ShowMessage('FILEOPEN');
    AVIERR_COMPRESSOR   : ShowMessage('COMPRESSOR');
    AVIERR_NOCOMPRESSOR : ShowMessage('NOCOMPRESSOR');
    AVIERR_READONLY     : ShowMessage('READONLY');
    AVIERR_NODATA       : ShowMessage('NODATA');
    AVIERR_BUFFERTOOSMALL: ShowMessage('BUFFERTOOSMALL');
    AVIERR_CANTCOMPRESS : ShowMessage('CANTCOMPRESS');
    AVIERR_USERABORT    : ShowMessage('USERABORT');
    AVIERR_ERROR        : ShowMessage('ERROR');
    REGDB_E_CLASSNOTREG	: ShowMessage('CLASSNOTREG');
else ShowMessage('Unknown Error');
   end;
    Raise Exception.Create('No se pudo abrir el archivo');
 end;

 Bitmap := TBitmap.create;  // Shevin added
 Desti:=Bitmap.Canvas;      // Shevin added

 if AVIERR_NODATA=AVIFILEGetStream(pavi,pavis,streamtypeVIDEO,0) then
  Raise Exception.Create('Error no hay pista de audio');
 principio:=AVIStreamStart(pavis);
 fin:=AVIStreamENd(pavis);
 trackbar1.Max:=AVIStreamLength(pavis)-1;
 ob:=AVIStreamGetFrameOpen(pavis,nil);
 if nil=ob then
  Raise Exception.Create('Error en Frameopen');
 han:=DrawDIBOpen;
 try
  new(info);
  AviStreamInfo(pavis,info,sizeof(TAVISTREAMINFOA));
  microsperframe:=Trunc(1000 / (info^.dwRate/info^.dwScale));
  dispose(info);
  DrawDIBStart(han,microsperframe);
  i:=trackbar1.Position;
  image1.Picture:=image2.Picture;
  if 0<>AVIStreamBeginStreaming(pavis,principio,fin,1000) then
   Raise Exception.Create('Error n AVIBegin');
  pbmi:=AVIStreamGetFrame(ob,i);

  FrameIndex := trackbar1.Position;

  Punter:=Pointer(Integer(pbmi)+pbmi^.biSize);

  DRawDIBBegin(han,desti.handle,0,0,pbmi,pbmi^.biWidth,pbmi^.biheight,DDF_ANIMATE);
  DrawDIBRealize(han,desti.handle,false);

  // Statements added by Shevin to set the size of the bitmap.
  Bitmap.width := pbmi^.biWidth;
  Bitmap.height := pbmi^.biHeight;

  DrawDIBDraw(han,desti.handle,0,0,pbmi^.biWidth,pbmi^.biheight,pbmi,Punter,0,0,pbmi^.biwidth,pbmi^.biheight,0);
  DrawDIBEnd(han);

  //  Shevin: Added for testing
  Image1.Canvas.draw(0,0,Bitmap);

  Application.ProcessMessages;
  pbmi:=AVIStreamGetFrame(ob,i);

  AVIStreamEndStreaming(pavis);
  DrawDIBStop(han);
 finally
  DrawDIBClose(han);
 end;
 AVIStreamGetFrameClose(ob);
 AVIStreamRelease(pavis);
 Bitmap.free;  // Shevin: Added for testing
end;

procedure TForm1.ShowAvi(FFilename : string);
var
 FrameIndex:  INTEGER;
 pavi:PAVIFile;
 pavis:PAVIStream;
 pavisound:PAVIStream;
 ob:PGetFrame;
 pbmi:PBitmapInfoHeader;
 Punter:PByte;
 han,i:integer;
 Desti:TCanvas;
 microsperframe:integer;
 principio,fin:integer;
 Picture: TPicture;
 filename:string;
 startime:TDateTime;
 percent:real;
 cur,n:integer;
 JPEG:TJPEGImage;

   // Shevin: Variables added
   info  : PAVISTREAMINFOA;
   bitmap : TBitmap;
   AviOpen : integer;
   hexcode : string;
   EMsg : string;
   lasterr : integer;
begin
  panel1.Caption:='';
  // Shevin: save return code from AVIFileOpen to determine error msg.
  AviOpen := AVIFIleOpen(pavi,Pchar(FFilename),OF_READ,nil);
  if 0<>AviOpen then
  begin
   case AviOpen of
    AVIERR_UNSUPPORTED  : ShowMessage('UNSUPPORTED');
    AVIERR_BADFORMAT    : ShowMessage('BADFORMAT');
    AVIERR_MEMORY       : ShowMessage('MEMORY');
    AVIERR_INTERNAL     : ShowMessage('INTERNAL');
    AVIERR_BADFLAGS     : ShowMessage('BADFLAGS');
    AVIERR_BADPARAM     : ShowMessage('BADPARM');
    AVIERR_BADSIZE      : ShowMessage('BADSIZE');
    AVIERR_BADHANDLE    : ShowMessage('BADHANDLE');
    AVIERR_FILEREAD     : ShowMessage('FILEREAD');
    AVIERR_FILEWRITE    : ShowMessage('FILEWRITE');
    AVIERR_FILEOPEN     : ShowMessage('FILEOPEN');
    AVIERR_COMPRESSOR   : ShowMessage('COMPRESSOR');
    AVIERR_NOCOMPRESSOR : ShowMessage('NOCOMPRESSOR');
    AVIERR_READONLY     : ShowMessage('READONLY');
    AVIERR_NODATA       : ShowMessage('NODATA');
    AVIERR_BUFFERTOOSMALL: ShowMessage('BUFFERTOOSMALL');
    AVIERR_CANTCOMPRESS : ShowMessage('CANTCOMPRESS');
    AVIERR_USERABORT    : ShowMessage('USERABORT');
    AVIERR_ERROR        : ShowMessage('ERROR');
    REGDB_E_CLASSNOTREG	: ShowMessage('CLASSNOTREG');
else ShowMessage('Unknown Error');
   end;
    Raise Exception.Create('Unknown Error');
 end;

 statusbar1.Panels[0].Text:='Loaded Image';
 GifAnimateBegin;
 Bitmap := TBitmap.create;  // Shevin added
 Desti:=Bitmap.Canvas;      // Shevin added

 if AVIERR_NODATA=AVIFILEGetStream(pavi,pavis,streamtypeVIDEO,0) then
  Raise Exception.Create('Error, only audio.');
 principio:=AVIStreamStart(pavis);
 fin:=AVIStreamENd(pavis);
 statusbar1.Panels[0].Text:='Found Stream Markers';
 statusbar1.Panels[0].Text:=IntToStr(fin)+' Frames Found.';
 ob:=AVIStreamGetFrameOpen(pavis,nil);
 if nil=ob then
  Raise Exception.Create('Error in Frameopen');
 han:=DrawDIBOpen;
 progressbar1.Max:=(trackbar1.SelEnd-trackbar1.SelStart)+3;
 filename:=ExtractFilePath(FFilename) + ExtractFileName(FFilename);
 cur:=0;
 n:=1;
 statusbar1.Panels[0].Text:='Adding Frames To Array';
 try
           //  Shevin: The computation of microsperframe refers to "info," which
           //  wasn't defined. I added code to acquire the stream info header.
           //  I also changed the numerator to 1000 from 1000000.
           new(info);
           AviStreamInfo(pavis,info,sizeof(TAVISTREAMINFOA));
           microsperframe:=Trunc(1000 / (info^.dwRate/info^.dwScale));
           dispose(info);
//  microsperframe:=Trunc(100/(info.dwRate/info.dwScale)); // Shevin deleted
//  DrawDIBStart(han,microsperframe);                          // Shevin deleted
  DrawDIBStart(han,microsperframe);
  i:=trackbar1.SelStart;
  if 0<>AVIStreamBeginStreaming(pavis,principio,fin,1000) then
   Raise Exception.Create('Error n AVIBegin');
  pbmi:=AVIStreamGetFrame(ob,i);

  FrameIndex := i;
  startime:=now;

  While pbmi<>Nil do
  begin
  progressbar1.StepBy(1);
  form1.Text:='AVI2GIF - '+FloatToStrF(progressbar1.position / progressbar1.max*100, ffFixed, 4, 2)+'%';
  statusbar1.Panels[1].Text:=Timetostr(now-startime);
   Punter:=Pointer(Integer(pbmi)+pbmi^.biSize);

DRawDIBBegin(han,desti.handle,0,0,pbmi,pbmi^.biWidth,pbmi^.biheight,DDF_ANIMATE);
   DrawDIBRealize(han,desti.handle,false);

   // Statements added by Shevin to set the size of the bitmap.
   Bitmap.width := pbmi^.biWidth;
   Bitmap.height := pbmi^.biHeight;

DrawDIBDraw(han,desti.handle,0,0,pbmi^.biWidth,pbmi^.biheight,pbmi,Punter,0,
0,pbmi^.biwidth,pbmi^.biheight,0);
   DrawDIBEnd(han);

   //  Shevin: Added for testing
   if checkbox1.Checked then
     Image1.Canvas.draw(0,0,Bitmap);

   // efg added to save frames to disk
   GifAnimateAddImage(Bitmap, False, microsperframe);
   if (checkbox2.Checked) and (n=cur+strtoint(edit1.text)) then
     begin
     cur:=n;
     JPEG := TJPEGImage.Create;
     JPEG.CompressionQuality := 80;
     JPEG.Assign(Bitmap);
     JPEG.SaveToFile(Format(filename+'%2.2d.jpg', [FrameIndex]));
     jpeg.free;
     end;
   n:=n+1;

   Application.ProcessMessages;
   inc(i);
   pbmi:=AVIStreamGetFrame(ob,i);
   INC (FrameIndex);
   if i>trackbar1.SelEnd then
     begin
     i:=trackbar1.Max;
     frameindex:=i;
     end;
  end;
  progressbar1.StepBy(1);
  form1.Text:='AVI2GIF - '+FloatToStrF(progressbar1.position / progressbar1.max*100, ffFixed, 4, 2)+'%';
  statusbar1.Panels[0].Text:='Added Frames';

  AVIStreamEndStreaming(pavis);
  DrawDIBStop(han);
 finally
  DrawDIBClose(han);
 end;
 AVIStreamGetFrameClose(ob);
 AVIStreamRelease(pavis);
 Bitmap.free;  // Shevin: Added for testing
 statusbar1.Panels[0].Text:='Constructing GIF';
 Picture := GifAnimateEndPicture;
 progressbar1.StepBy(1);
 form1.Text:='AVI2GIF - '+FloatToStrF(progressbar1.position / progressbar1.max*100, ffFixed, 4, 2)+'%';
 statusbar1.Panels[0].Text:='Saving To File';
 Picture.SaveToFile(filename+'.gif');  // save gif
 progressbar1.StepBy(1);
 form1.Text:='AVI2GIF - '+FloatToStrF(progressbar1.position / progressbar1.max*100, ffFixed, 4, 2)+'%';
 Picture.Free;
 statusbar1.Panels[1].Text:=Timetostr(now-startime);
 showmessage('Complete! Done in '+statusbar1.Panels[1].Text);
 statusbar1.Panels[0].Text:='Done!';
 image1.Picture.LoadFromFile(filename+'.gif');
end;

// Shevin: The initialization and finalization sections are required for
// use with Windows NT and Win 2000.
procedure TForm1.FormResize(Sender: TObject);
begin
panel1.Width:=form1.Width-8;
image1.Width:=form1.Width-26;
progressbar1.Width:=form1.Width-96;
trackbar1.Width:=form1.Width-93;
button1.Top:=form1.Height-81;
button2.Left:=form1.Width-98;
button3.Left:=form1.Width-58;
progressbar1.Top:=form1.Height-81;
checkbox1.Top:=form1.Height-105;
checkbox2.Top:=form1.Height-105;
edit1.Top:=form1.Height-105;
trackbar1.Top:=form1.Height-140;
button2.Top:=form1.Height-140;
button3.Top:=form1.Height-140;
label1.Top:=form1.Height-103;
panel1.Height:=form1.Height-143;
image1.Height:=form1.Height-159;
statusbar1.Panels[0].Width:=form1.Width-80
end;

procedure TForm1.FormShow(Sender: TObject);
begin
Showmessage('Made by Lewis Oaten (sphyrz@yahoo.co.uk).  By clicking ok, you agree i am better then you!');
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
loadavi(opendialog1.Filename);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
trackbar1.SelStart:=trackbar1.Position;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
trackbar1.SelEnd:=trackbar1.Position;
end;

initialization
  CoInitialize(nil);

finalization
  CoUnInitialize();

end.


