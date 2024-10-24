unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Buttons, LCLType, ZConnection, ZDataset;

type

  { TfmMain }

  TfmMain = class(TForm)
    bbStart: TBitBtn;
    bbNext: TBitBtn;
    cbDriverList: TComboBox;
    edClientLibrary: TEdit;
    edUser: TEdit;
    edTo: TEdit;
    edFrom: TEdit;
    edPass: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lbUser: TLabel;
    lbProgress: TLabel;
    lbTables: TListBox;
    lbPumpTables: TListBox;
    lbPass: TLabel;
    mmLog: TMemo;
    odFind: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    pcData: TPageControl;
    Progress: TProgressBar;
    sbAdd: TSpeedButton;
    sbRemove: TSpeedButton;
    sbConnectFrom: TSpeedButton;
    sbFindTo: TSpeedButton;
    sbFindFrom: TSpeedButton;
    sbAddAll: TSpeedButton;
    sbRemoveAll: TSpeedButton;
    StatusBar1: TStatusBar;
    tsFromData: TTabSheet;
    tsToData: TTabSheet;
    cnFrom: TZConnection;
    cnTo: TZConnection;
    qTableList: TZQuery;
    qFromData: TZQuery;
    qToData: TZQuery;
    procedure bbNextClick(Sender: TObject);
    procedure bbStartClick(Sender: TObject);
    procedure cbDriverListChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lbTablesDblClick(Sender: TObject);
    procedure sbAddAllClick(Sender: TObject);
    procedure sbAddClick(Sender: TObject);
    procedure sbConnectFromClick(Sender: TObject);
    procedure sbFindFromClick(Sender: TObject);
    procedure sbFindToClick(Sender: TObject);
    procedure sbRemoveAllClick(Sender: TObject);
    procedure sbRemoveClick(Sender: TObject);
  private
    function OpenDBFile: String;
    procedure ProccessTable(const TableName: String; const Index: Integer);
  public
  end;


var
  fmMain: TfmMain;

implementation

{$R *.lfm}

{ TfmMain }

procedure TfmMain.sbFindFromClick(Sender: TObject);
begin
  edFrom.Text := OpenDBFile;
end;

procedure TfmMain.bbNextClick(Sender: TObject);
begin
  pcData.ActivePage := tsToData;
end;

procedure TfmMain.bbStartClick(Sender: TObject);
begin
  if Trim(edTo.Text) <> '' then
  begin
    if Application.MessageBox('O banco de dados destino deve estar vazio e já deve estar com o CharSet correto!','Confirma?',MB_YESNO+MB_DEFBUTTON2) = mrNo then Exit;
    cnTo.Connected := False;
    cnTo.LibraryLocation := edClientLibrary.Text;
    cnTo.User := edUser.Text;
    cnTo.Password := edPass.Text;
    cnTo.Database := edTo.Text;
    cnTo.Connect;
  end else
  begin
    ShowMessage('Indique o banco de dados destino!');
    Exit;
  end;
  bbStart.Enabled := False;
  Progress.Max := lbPumpTables.Count;
  mmLog.Clear;
  Application.ProcessMessages;
  lbPumpTables.Items.ForEach(@ProccessTable);
  Progress.Position := Progress.Max;
  bbStart.Enabled := True;
end;

procedure TfmMain.cbDriverListChange(Sender: TObject);
begin
  cnFrom.Protocol := cbDriverList.Text;
  cnTo.Protocol := cbDriverList.Text;
  if Pos('firebird',cbDriverList.Text) > 0 then
    edClientLibrary.Text := 'fbclient.dll';
end;

procedure TfmMain.FormCreate(Sender: TObject);
var List: TStringList;
begin
  List := TStringList.Create;
  cnFrom.GetProtocolNames(List);
  cbDriverList.Clear;
  cbDriverList.Items.AddStrings(List);
  cbDriverList.ItemIndex := cbDriverList.Items.IndexOf('firebird');
  if cbDriverList.ItemIndex > 0 then
    cbDriverListChange(Sender);
end;

procedure TfmMain.lbTablesDblClick(Sender: TObject);
begin
  sbAdd.Click;
end;

procedure TfmMain.sbAddAllClick(Sender: TObject);
begin
  lbPumpTables.Items.AddStrings(lbTables.Items);
  lbTables.Clear;
end;

procedure TfmMain.sbAddClick(Sender: TObject);
begin
  if lbTables.ItemIndex < 0 then lbTables.ItemIndex := 0;
  lbPumpTables.Items.Add(lbTables.Items[lbTables.ItemIndex]);
  lbTables.Items.Delete(lbTables.ItemIndex);
end;

procedure TfmMain.sbConnectFromClick(Sender: TObject);
begin
  if Trim(edFrom.Text) <> '' then
  begin
    cnFrom.Connected := False;
    cnFrom.LibraryLocation := edClientLibrary.Text;
    cnFrom.User := edUser.Text;
    cnFrom.Password := edPass.Text;
    cnFrom.Database := edFrom.Text;
    cnFrom.Connect;
    qTableList.Open;
    while not qTableList.EOF do
    begin
      lbTables.Items.Add(qTableList.Fields[0].Text);
      qTableList.Next;
    end;
    qTableList.Close;
  end;
end;

procedure TfmMain.sbFindToClick(Sender: TObject);
begin
  edTo.Text := OpenDBFile;
end;

procedure TfmMain.sbRemoveAllClick(Sender: TObject);
begin
  lbTables.Items.AddStrings(lbPumpTables.Items);
  lbPumpTables.Clear;
end;

procedure TfmMain.sbRemoveClick(Sender: TObject);
begin
  if lbPumpTables.ItemIndex < 0 then lbPumpTables.ItemIndex := 0;
  lbTables.Items.Add(lbPumpTables.Items[lbPumpTables.ItemIndex]);
  lbPumpTables.Items.Delete(lbPumpTables.ItemIndex);
end;

function TfmMain.OpenDBFile: String;
begin
  odFind.InitialDir := ExtractFilePath(Application.ExeName);
  if odFind.Execute then
  begin
    Result := odFind.FileName;
  end;
end;

procedure TfmMain.ProccessTable(const TableName: String; const Index: Integer);
var
  i, iIncrement: Integer;
begin
  if TableName <> '' then
  begin
    Progress.Position := Index;
    if mmLog.Lines.Count = 0 then mmLog.Lines.Add('----------------------------------------------');
    mmLog.Lines.Add('Prossecing table: '+TableName+'...');
    Application.ProcessMessages;

    qFromData.SQL.Text := 'SELECT * FROM '+TableName;
    qFromData.Open;
    qToData.SQL.Text := qFromData.SQL.Text+' WHERE 1 = 0';
    iIncrement := qFromData.RecordCount div 20;
    mmLog.Lines.Add('');
    while not qFromData.EOF do
    begin
      qToData.Open;
      qToData.Append;
      for i := 0 to qToData.Fields.Count - 1 do
        qToData.Fields[i].Value := qFromData.Fields[i].Value;
      qToData.Post;
      qFromData.Next;
      if (iIncrement > 0) and (qFromData.RecNo mod iIncrement = 0) then
      begin
        mmLog.Lines.Strings[mmLog.Lines.Count-1] := StringOfChar('=',qFromData.RecNo div iIncrement);
        Application.ProcessMessages;
      end;
      qToData.Close;
    end;
    qFromData.Close;
    mmLog.Lines.Strings[mmLog.Lines.Count-1] := StringOfChar('=',20);
    mmLog.Lines.Add('');
  end;
end;

end.

