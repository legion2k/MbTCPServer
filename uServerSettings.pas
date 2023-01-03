unit uServerSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Layouts, FMX.Controls.Presentation,
  System.Rtti, FMX.Grid.Style, FMX.ScrollBox, FMX.Grid, FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.ListBox, uEditSendData;

type
  TfmServerSettings = class(TFrame)
    PanelLeft: TPanel;
    ScrollBox: TScrollBox;
    Splitter1: TSplitter;
    Label1: TLabel;
    Edit_Port: TSpinBox;
    Label3: TLabel;
    Edit_MaxConn: TSpinBox;
    Label2: TLabel;
    Edit_TimeoutConn: TSpinBox;
    Label5: TLabel;
    Edit_IP: TEdit;
    GroupBox1: TGroupBox;
    Label4: TLabel;
    Edit_SleepTime: TSpinBox;
    Answer_OK: TRadioButton;
    Answer_Data: TRadioButton;
    Answer_Mute: TRadioButton;
    Answer_Error: TRadioButton;
    Answer_Full: TRadioButton;
    Answer_ADU: TRadioButton;
    Edit_Error: TComboBox;
    ListBoxItem1: TListBoxItem;
    ListBoxItem2: TListBoxItem;
    ListBoxItem3: TListBoxItem;
    ListBoxItem4: TListBoxItem;
    ListBoxItem5: TListBoxItem;
    ListBoxItem6: TListBoxItem;
    ListBoxItem7: TListBoxItem;
    ListBoxItem8: TListBoxItem;
    ListBoxItem9: TListBoxItem;
    Edit_Data: TfmEditSendData;
    Edit_ADU: TfmEditSendData;
    Edit_Full: TfmEditSendData;
    Label6: TLabel;
    Edit_Addr: TSpinBox;
    TimerUpdateData: TTimer;
    GridInfo: TStringGrid;
    Col_ID: TIntegerColumn;
    Col_LocalIP: TStringColumn;
    Col_RemoteIP: TStringColumn;
    Col_BytesIn: TIntegerColumn;
    Col_BytesOut: TIntegerColumn;
    procedure Answer_Change(Sender: TObject);
    procedure Edit_ErrorChange(Sender: TObject);
    procedure Edit_DataEditChangeTracking(Sender: TObject);
    procedure Edit_ADUEditChangeTracking(Sender: TObject);
    procedure Edit_FullEditChangeTracking(Sender: TObject);
    procedure TimerUpdateDataTimer(Sender: TObject);
  private
    type TOnAnswerChange = procedure( const AnswerType: Byte; const AnswerData: AnsiString ) of object;
    var _OnAnswerChange: TOnAnswerChange;
    procedure AnswerChange( const Answer: Byte; const Data: AnsiString );
  public
    { Public declarations }
    property OnAnswerChange: TOnAnswerChange read _OnAnswerChange write _OnAnswerChange;
    procedure getAnswerSets(out AnswerType: Byte; out AnswerData: AnsiString);
  end;

implementation

{$R *.fmx}

uses uMain, System.Generics.Collections, uModbusServer, uModbusSrvClient;

procedure TfmServerSettings.AnswerChange(const Answer: Byte; const Data: AnsiString);
begin
  if Assigned(OnAnswerChange) then
    OnAnswerChange(Answer, data)
end;

procedure TfmServerSettings.Answer_Change(Sender: TObject);
begin
  var ch := (Sender as TRadioButton);
  case ch.Tag of
    //0://OK
    1:begin//Mute
      if ch.IsChecked then
        AnswerChange(ch.Tag, '');
    end;
    2:begin //Error
      //Edit_Error.Enabled := ch.IsChecked;
      if ch.IsChecked then
        AnswerChange(ch.Tag, AnsiChar(Edit_Error.Selected.Tag));
    end;
    3:begin //Data
      //Edit_Data.Enabled := ch.IsChecked;
      if ch.IsChecked then
        AnswerChange(ch.Tag, Edit_Data.Value);
    end;
    4:begin //ADU
      //Edit_ADU.Enabled := ch.IsChecked;
      if ch.IsChecked then
        AnswerChange(ch.Tag, Edit_ADU.Value);
    end;
    5:begin //Full
      //Edit_Full.Enabled := ch.IsChecked;
      if ch.IsChecked then
        AnswerChange(ch.Tag, Edit_Full.Value);
    end;
  else//0-Nornal
    if ch.IsChecked then
      AnswerChange(0, '');
  end;
end;

procedure TfmServerSettings.Edit_ErrorChange(Sender: TObject);
begin
  var ch := Answer_Error;
  if ch.IsChecked then
    AnswerChange(ch.Tag, AnsiChar(Edit_Error.Selected.Tag));
end;

procedure TfmServerSettings.Edit_DataEditChangeTracking(Sender: TObject);
begin
  Edit_Data.EditChangeTracking(Sender);

  var ch := Answer_Data;
  if ch.IsChecked then
    AnswerChange(ch.Tag, Edit_Data.Value);
end;

procedure TfmServerSettings.Edit_ADUEditChangeTracking(Sender: TObject);
begin
  Edit_ADU.EditChangeTracking(Sender);

  var ch := Answer_ADU;
  if ch.IsChecked then
    AnswerChange(ch.Tag, Edit_ADU.Value);
end;

procedure TfmServerSettings.Edit_FullEditChangeTracking(Sender: TObject);
begin
  Edit_Full.EditChangeTracking(Sender);

  var ch := Answer_Full;
  if ch.IsChecked then
    AnswerChange(ch.Tag, Edit_Full.Value);
end;

procedure TfmServerSettings.getAnswerSets(out AnswerType: Byte; out AnswerData: AnsiString);
begin
  if Answer_OK.IsChecked then begin
    AnswerType := Answer_OK.Tag;
    AnswerData := ''
  end else
  if Answer_Mute.IsChecked then begin
    AnswerType := Answer_Mute.Tag;
    AnswerData := ''
  end else
  if Answer_Error.IsChecked then begin
    AnswerType := Answer_Error.Tag;
    AnswerData := AnsiChar(byte(Edit_Error.Selected.Tag));
  end else
  if Answer_Data.IsChecked then begin
    AnswerType := Answer_Data.Tag;
    AnswerData := Edit_Data.Value;
  end else
  if Answer_ADU.IsChecked then begin
    AnswerType := Answer_ADU.Tag;
    AnswerData := Edit_ADU.Value;
  end else
  if Answer_Full.IsChecked then begin
    AnswerType := Answer_Full.Tag;
    AnswerData := Edit_Full.Value;
  end else begin
    AnswerType := 0;
    AnswerData := '';
  end;
end;

procedure TfmServerSettings.TimerUpdateDataTimer(Sender: TObject);
type
  TListKey = System.Generics.Collections.TList<UInt64>;
var
  csInfo: TClientsInfo;
  cInf: TClientInfo;
  i,j: Integer;
  id: UInt64;
  ListKey: TListKey;
begin
  if Assigned(fMain.ModbusServer) then begin
    csInfo := fMain.ModbusServer.GetInfo();
    try
      fMain.Label_CountConnection.Text := csInfo.Count.ToString;
      GridInfo.BeginUpdate;
      try
        i := GridInfo.RowCount;
        while i>0 do begin
          Dec(i);
          id := StrToUInt64( GridInfo.Cells[Col_ID.Index, i] );
          if csInfo.TryGetValue(id, cInf)then begin
            //GridInfo.Cells[Col_ID.Index,       i] := cInf.ID.ToString;
            //GridInfo.Cells[Col_LocalIP.Index,  i] := cInf.localIP;
            //GridInfo.Cells[Col_RemoteIP.Index, i] := cInf.remoteIP;
            GridInfo.Cells[Col_BytesIn.Index,  i] := cInf.BytesIn.ToString;
            GridInfo.Cells[Col_BytesOut.Index, i] := cInf.BytesOut.ToString;
            csInfo.Remove(id)
          end else begin
            //удаляем
            j:=i;
            while j<GridInfo.RowCount-1 do begin
              GridInfo.Cells[0, j] := GridInfo.Cells[0, j+1];
              GridInfo.Cells[1, j] := GridInfo.Cells[1, j+1];
              GridInfo.Cells[2, j] := GridInfo.Cells[2, j+1];
              GridInfo.Cells[3, j] := GridInfo.Cells[3, j+1];
              GridInfo.Cells[4, j] := GridInfo.Cells[4, j+1];
              inc(j);
              //Application.ProcessMessages;
            end;
            GridInfo.RowCount := GridInfo.RowCount - 1;
          end;
        end;
        // добавляем оставшиеся
        if csInfo.Count>0 then begin
          ListKey := TListKey.Create(csInfo.Keys);
          try
            ListKey.Sort();
            for id in ListKey do begin
              cInf := csInfo[id];
              i := GridInfo.RowCount;
              GridInfo.RowCount := i + 1;
              GridInfo.Cells[Col_ID.Index,       i] := cInf.ID.ToString;
              GridInfo.Cells[Col_LocalIP.Index,  i] := cInf.localIP;
              GridInfo.Cells[Col_RemoteIP.Index, i] := cInf.remoteIP;
              GridInfo.Cells[Col_BytesIn.Index,  i] := cInf.BytesIn.ToString;
              GridInfo.Cells[Col_BytesOut.Index, i] := cInf.BytesOut.ToString;
            end;
          finally
            FreeAndNil(ListKey);
          end;
        end;
      finally
        GridInfo.EndUpdate;
      end;
    finally
      FreeAndNil(csInfo);
    end;
  end else begin
    GridInfo.RowCount := 0;
    fMain.Label_CountConnection.Text := '0';
  end;
end;

end.
