unit uMapRegs;

interface

uses
  FMX.TextLayout, System.Generics.Collections,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, System.Rtti, FMX.Grid.Style, FMX.Grid,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.ListBox, FMX.Layouts, uGrid,
  Data.Bind.EngExt, Fmx.Bind.DBEngExt, Data.Bind.Components, FMX.Memo.Types, FMX.Memo, FMX.Menus;

type
  TevntRegAddrNotify = procedure (const ARegAddr: UInt16) of object;
  TevntRegAddrEdit = procedure (const iRegAddr: UInt16; const sRegAddr: string) of object;
  TevntGetRegText = procedure (const ARegAddr: UInt16; out Text: string) of object;

  TfmMapRegs = class(TFrame)
    PanelTop: TPanel;
    Layout_Addr: TLayout;
    Label18: TLabel;
    Layout_ColWidth: TLayout;
    Label2: TLabel;
    EditColWidth: TSpinBox;
    EditAddr: TEdit;
    Edit_Addr_ButtonUp: TEditButton;
    Edit_Addr_ButtonDown: TEditButton;
    Layout_ColCount: TLayout;
    AutoColCount: TCheckBox;
    EditColCount: TSpinBox;
    Layout_AddrView: TLayout;
    EditAddrView: TComboBox;
    ListBoxItem1: TListBoxItem;
    ListBoxItem2: TListBoxItem;
    ListBoxItem3: TListBoxItem;
    ListBoxItem4: TListBoxItem;
    Label16: TLabel;
    fmGrid: TfmGrid;
    PopupMenu: TPopupMenu;
    MenuItem_CheckSel: TMenuItem;
    MenuItem_UnCheckSel: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem_UnCheckAll: TMenuItem;
    procedure EditAddrViewChange(Sender: TObject);
    procedure Edit_Addr_ButtonUpClick(Sender: TObject);
    procedure Edit_Addr_ButtonDownClick(Sender: TObject);
    procedure EditAddrChange(Sender: TObject);
    procedure EditAddrExit(Sender: TObject);
    procedure Grid_DrawColumnCell(Sender: TObject; const Canvas: TCanvas; const Column: TColumn; const Bounds: TRectF;
      const Row: Integer; const Value: TValue; const State: TGridDrawStates);
    procedure EditColWidthChange(Sender: TObject);
    procedure AutoColCountChange(Sender: TObject);
    procedure EditColCountChange(Sender: TObject);
    procedure GridFixCol_GetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
    procedure fmGridGridCellDblClick(const Column: TColumn; const Row: Integer);
    procedure MenuItem_CheckSelClick(Sender: TObject);
    procedure MenuItem_UnCheckSelClick(Sender: TObject);
    procedure MenuItem_UnCheckAllClick(Sender: TObject);
  private
    RegAddr: UInt16;
    RegAddrInChange: Boolean;
    function RefreshAddr(newAddr: Word): Boolean;
    var
    evntChangeRegAddr: TevntRegAddrNotify;
    evntEditRegAddr: TevntRegAddrEdit;
    evntGetRegText: TevntGetRegText;
    textLayout: TTextLayout;
    _colorCurrent: TAlphaColor;
    _colorSelect: TAlphaColor;
    _colorCheck: TAlphaColor;
    procedure ColumnName(Index: Integer);
  public
    type
      TSelRegs = System.Generics.Collections.TList<UInt16>;
  private
    type
      TSelRegType = (srtOne, srtRect, srtPosled);
    var
      chkRegs, selRegs: TSelRegs;
      selRegsStart: record
        reg : UInt16;
        sel: Boolean;
      end;
    procedure MultiSelect(ACol, ARow: integer; selType: TSelRegType);
    function makeVisibleCell(Reg: UInt16): boolean; overload;
    function makeVisibleCell(const ACol, ARow: integer): boolean; overload;
    procedure OnGridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    //procedure OnGridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    //procedure OnGridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure OnGridKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    //procedure OnGridKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    function AddrToString(addr: UInt16): string;
  published
    property ColorCurrent: TAlphaColor read _colorCurrent write _colorCurrent;
    property ColorSelect: TAlphaColor read _colorSelect write _colorSelect;
    property ColorCheck: TAlphaColor read _colorCheck write _colorCheck;
    //
    property OnChangeRegAddr: TevntRegAddrNotify read evntChangeRegAddr write evntChangeRegAddr;
    property OnGetRegText: TevntGetRegText read evntGetRegText write evntGetRegText;
    property OnEditReg: TevntRegAddrEdit read evntEditRegAddr write evntEditRegAddr;
    //
    procedure RefreshCurrAddr();
  public
    property CheckRegs: TSelRegs read chkRegs;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  System.Math, System.RegularExpressions, uTools, FMX.Header;

const
  ShiftText = 2;

{$R *.fmx}

constructor TfmMapRegs.Create(AOwner: TComponent);
begin
  inherited;
  _colorCurrent := TAlphaColor($FF_0000FF);
  _colorSelect := TAlphaColor($FF_2A96FF);
  _colorCheck := TAlphaColor($FF_c4e100);
  //-----------------------
  fmGrid.ColumnName := ColumnName;
  RegAddrInChange := False;
  RegAddr := 1;
  RefreshAddr(0);
  selRegsStart.reg := 0;
  selRegsStart.sel := False;
  //-----------------------
  chkRegs := TSelRegs.Create;
//  for var i:=0 to 100 do
//    chkRegs.Add(i);
//  chkRegs.Add(0);
  selRegs := TSelRegs.Create;
  //-----------------------
  textLayout := TTextLayoutManager.DefaultTextLayout.Create;
  textLayout.BeginUpdate;
  textLayout.Text := '';
  textLayout.WordWrap := False;
  textLayout.Trimming := fmGrid.Grid.TextSettings.Trimming;
  textLayout.Font := fmGrid.Grid.TextSettings.Font;
  textLayout.Color := fmGrid.Grid.TextSettings.FontColor;
  textLayout.HorizontalAlign := fmGrid.Grid.TextSettings.HorzAlign;
  textLayout.VerticalAlign := fmGrid.Grid.TextSettings.VertAlign;
  textLayout.EndUpdate;
  //-----------------------
  fmGrid.Grid.OnMouseDown := OnGridMouseDown;
  //fmGrid.Grid.OnMouseUp   := OnGridMouseUp;
  //fmGrid.Grid.OnMouseMove := OnGridMouseMove;
  fmGrid.Grid.OnKeyDown   := OnGridKeyDown;
  //fmGrid.Grid.OnKeyUp     := OnGridKeyUp;
  fmGrid.Grid.Hint := 'Для выделения группы нажимете:'#10+
    'Alt - выделить прямоугольную область,'#10+
    'Shft - выделить область последовательно';
  fmGrid.Grid.ShowHint := True;
end;

destructor TfmMapRegs.Destroy;
begin
  FreeAndNil(textLayout);
  FreeAndNil(selRegs);
  FreeAndNil(chkRegs);
  inherited;
end;
//----------------------------------------------------------------------------------------------------------------------
// закраска
//----------------------------------------------------------------------------------------------------------------------
procedure TfmMapRegs.Grid_DrawColumnCell(Sender: TObject; const Canvas: TCanvas; const Column: TColumn;
  const Bounds: TRectF; const Row: Integer; const Value: TValue; const State: TGridDrawStates);
var
  rct, r: TRectF;
  reg: Integer;
  regData: string;
  cnv: TCanvas;
  clrBck, {clrRct,} clrSel: TAlphaColor;
begin
  { Delphi 11.2 - рисование линий происходит с использование альфа-канала,
  хотя везде выставлено max (255 или 1.0),
  поэтому рисуем рамку с помощью заливки.
  PS: линия не ресуется шириной меньше 2px. Как следствие если ставить 1px, то
  ширина остается 2px, а линия начинает размываться (c помощью альфа-канала) наверное на 50%
  }
  if fmGrid.Cols = 0 then exit;
  cnv := Canvas;
  rct := Bounds;
  rct.Inflate(3, 3); // Востанавливаем размер ячейки
  //rct.BottomRight.Offset(1,1);
  cnv.BeginScene;
  try
    regData := '';
      clrSel := TAlphaColors.Null;
      reg := Row*(fmGrid.Cols);
      {if Column.Index=0 then begin
        regData := reg.ToString;
        clrBck := $FF_D6D6D6;
        clrRct := $FF_7a7a7a;
      end else }begin
        reg := reg + (Column.Index{-1});
        //clrRct := $FF_a0a0a0;
        if reg>65535 then begin
          clrBck := $FF_D6D6D6;
        end else begin
          if Assigned(evntGetRegText) then begin
            evntGetRegText(reg, regData);
          end else
            regData := '';
          //regData := 'AЖ000';
          //if (State * [TGridDrawState.Selected, TGridDrawState.Focused])<>[] then begin
          //if (Grid.Col=Column.Index) and (Grid.Row=Row) then begin
          if reg=RegAddr then begin
            clrSel := _colorCurrent;
          end else
          if selRegs.Contains(reg) then begin
            clrSel := _colorSelect;
          end;
          if chkRegs.Contains(reg) then begin
            clrBck := _colorCheck//$FF_c4e100;
          end else
          if odd(Row) then begin
            clrBck := $FF_f9f7ff;
          end else begin
            clrBck := $FF_ffffff;
          end;
        end;
      end;
      //cnv.DrawRectSides(rct, 0, 0, [], 1, [TSide.Bottom, TSide.Right]);//почему-то альфа канал прёт!? - линия не ресуется меньше 2px
      r := rct;
      //рисуем линии сетки
      //cnv.Fill.Color := clrRct;
      //cnv.FillRect(rct, 0, 0, [], 1);
      //рисуем рамку вокруг отмеченной ячейки
      //r.BottomRight.Offset(-1,-1);
      if clrSel<>TAlphaColors.Null then begin
        cnv.Fill.Color := clrSel;
        cnv.FillRect(r, 0, 0, [], 1);
        r.Inflate(-2,-2);
      end;
      //рисуем фон ячейки
      cnv.Fill.Color := clrBck;
      cnv.FillRect(r, 0, 0, [], 1);
      //текст
      textLayout.BeginUpdate;
      try
        textLayout.TopLeft := TPointF.Create(rct.Left+ShiftText+0, rct.Top+ShiftText+0);
        textLayout.MaxSize := TPointF.Create(rct.Width-ShiftText-1-2, rct.Height-ShiftText-1-2);
        textLayout.Color := fmGrid.Grid.TextSettings.FontColor;
        textLayout.Text := regData;
      finally
        textLayout.EndUpdate;
      end;
      textLayout.RenderLayout(cnv);
      //cnv.Fill.Color := TAlphaColors.Black;//grid.TextSettings.FontColor;
      //cnv.FillText(rct, regData, False, 1, [], TTextAlign.Center, TTextAlign.Center);
  finally
    cnv.EndScene;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------
// количество колонок
//----------------------------------------------------------------------------------------------------------------------

procedure TfmMapRegs.ColumnName(Index: Integer);
begin
//  if Index=0 then
//    s := 'xxxxx'
//  else
  fmGrid.Grid.Columns[Index].Header := AddrToString(Index);
end;

procedure TfmMapRegs.GridFixCol_GetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
begin
  case EditAddrView.ItemIndex of
    0: Value := (ARow * fmGrid.Cols).ToString;
    1: Value := (ARow * fmGrid.Cols + 1).ToString;
    2: Value := (ARow * fmGrid.Cols).ToHexString(0);
    3: Value := (ARow * fmGrid.Cols + 1).ToHexString(0);
  else
    Value := 'wtf?';
  end;
  //Value := ARow.ToString;
end;

function TfmMapRegs.AddrToString(addr: UInt16): string;
begin
  case EditAddrView.ItemIndex of
    0: Result := IntToStr(addr);
    1: Result := IntToStr(addr+1);
    2: Result := IntToHex(addr,1);
    3: Result := IntToHex(addr+1,1);
  else
    Result := 'wtf?';
  end;
end;

procedure TfmMapRegs.AutoColCountChange(Sender: TObject);
var v: UInt32;
begin
  EditColCount.Enabled := not AutoColCount.IsChecked;
  if AutoColCount.IsChecked then
    fmGrid.Cols := 0
  else begin
    v := Round(EditColCount.Value);
    if v<1 then
      v := 1;
    fmGrid.Cols := v;
  end;
end;

procedure TfmMapRegs.EditColCountChange(Sender: TObject);
begin
  fmGrid.Cols := Round(EditColCount.Value);
end;

procedure TfmMapRegs.EditColWidthChange(Sender: TObject);
begin
  fmGrid.DefColWidth := Round(EditColWidth.Value);
end;

//----------------------------------------------------------------------------------------------------------------------
procedure TfmMapRegs.EditAddrViewChange(Sender: TObject);
var i: Integer;
begin
  if fmGrid.Cols=0 then exit;
  for i:=0 to fmGrid.Cols-1 do
    ColumnName(i);
  //for i:=0 to Grid.RowCount-1 do
  fmGrid.FixCol.Model.ClearCache;
  fmGrid.FixCol.Repaint;
  RegAddrInChange := True;
  RefreshAddr(RegAddr);
  RegAddrInChange := false;
end;

//----------------------------------------------------------------------------------------------------------------------
// Изменение адреса регистра
//----------------------------------------------------------------------------------------------------------------------
function TfmMapRegs.RefreshAddr(newAddr: Word): Boolean;
var oRegAddr: UInt16;
begin
  oRegAddr := RegAddr;
  RegAddr := newAddr;
  Result := newAddr<>oRegAddr;
  //-----------------------------
  EditAddr.Text := AddrToString(newAddr);
  //-----------------------------
  if Result then
    RefreshCurrAddr;
  //-----------------------------
  EditAddr.SelStart := Length(EditAddr.Text);
  //-----------------------------
  if Result then
    if fmGrid.Cols>0 then begin
      if not makeVisibleCell(RegAddr) then begin
        fmGrid.Grid.Columns[ oRegAddr mod fmGrid.Cols ].UpdateCell( oRegAddr div fmGrid.Cols );
        fmGrid.Grid.Columns[ newAddr  mod fmGrid.Cols ].UpdateCell( newAddr  div fmGrid.Cols );
      end;
    end;
end;

procedure TfmMapRegs.RefreshCurrAddr;
begin
  if Assigned(evntChangeRegAddr) then
    evntChangeRegAddr(RegAddr);
end;

procedure TfmMapRegs.Edit_Addr_ButtonUpClick(Sender: TObject);
var r: UInt16;
begin
  if RegAddr=$FFFF then exit;
  r := RegAddr + 1;
  MultiSelect(r mod fmGrid.Cols, r div fmGrid.Cols, srtOne);
end;

procedure TfmMapRegs.Edit_Addr_ButtonDownClick(Sender: TObject);
var r: UInt16;
begin
  if RegAddr=0 then exit;
  r := RegAddr - 1;
  MultiSelect(r mod fmGrid.Cols, r div fmGrid.Cols, srtOne);
end;

procedure TfmMapRegs.EditAddrChange(Sender: TObject);
var s: string;
  v,e: Integer;
begin
  if RegAddrInChange then exit;
  if selRegs.Count>0 then begin
    selRegs.Clear;
    //selRegs.Add(RegAddr);
    fmGrid.Grid.Repaint;
  end;
  selRegsStart.sel := False;
  s := EditAddr.Text;
  if s='' then exit;
  //-----------------------------
  RegAddrInChange := True;
  case EditAddrView.ItemIndex of
    0,1: s := TRegEx.Replace(s, '(?si)[^\d]', '');
    2,3: s := '$'+TRegEx.Replace(s, '(?si)[^A-F\d]', '');
  end;
  if s='' then begin
    EditAddr.Text := '';
  end else begin
    Val(s, v, e);
    if e=0 then begin
      case EditAddrView.ItemIndex of
        1,3: //1..65536
          v := v-1;
      end;
      if v>$FFFF then
        v:=$FFFF
      else if v<0 then
        v:=0;
      if RefreshAddr(v) then
        if fmGrid.Cols>0 then begin
          makeVisibleCell(v);
        end;
    end;
  end;
  RegAddrInChange := False;
end;

procedure TfmMapRegs.EditAddrExit(Sender: TObject);
begin
  RegAddrInChange := True;
  RefreshAddr(RegAddr);
  RegAddrInChange := False;
end;

//----------------------------------------------------------------------------------------------------------------------
// Выделение
//----------------------------------------------------------------------------------------------------------------------
function TfmMapRegs.makeVisibleCell(Reg: UInt16): boolean;
begin
  Result := makeVisibleCell((Reg mod (fmGrid.Cols)) , reg div (fmGrid.Cols));
end;

function TfmMapRegs.makeVisibleCell(const ACol, ARow: integer): boolean;
var r, rCll: TRectF;
  x, y: Single;
begin
  r := TRectF.Create(fmGrid.Grid.ViewportPosition, fmGrid.Grid.ViewportSize.Width, fmGrid.Grid.ViewportSize.Height);
  rCll := fmGrid.Grid.CellRect(ACol, ARow);
  Result := not r.Contains(rCll);
  if not Result then exit;
  x := r.TopLeft.X;
  y := r.TopLeft.Y;
  if r.BottomRight.X < rCll.BottomRight.X then begin
    x := rCll.BottomRight.X - r.Width + 1;
  end else
  if r.TopLeft.X > rCll.TopLeft.X then begin
    x := rCll.TopLeft.X
  end;
  if r.BottomRight.Y < rCll.BottomRight.Y then begin
    y := rCll.BottomRight.y - r.Height + 1;
  end else
  if r.TopLeft.Y > rCll.TopLeft.Y then begin
    y := rCll.TopLeft.Y
  end;
  fmGrid.Grid.BeginUpdate;
  fmGrid.Grid.ScrollTo(x, y);
  fmGrid.Grid.EndUpdate;
end;

procedure TfmMapRegs.MultiSelect(ACol, ARow: integer; selType: TSelRegType);
var i,j, reg, r, col: Integer;
begin
  selRegs.Clear;
  reg := (ACol) + (fmGrid.Cols) * ARow;
  //------------------------------------------------
  if selType=TSelRegType.srtOne then begin
    if selRegsStart.sel then
      fmGrid.Grid.Repaint;
    selRegsStart.sel := False;
  end else begin
    //------------------------------------------------
    if not selRegsStart.sel then begin
      selRegsStart.reg := RegAddr;
      selRegsStart.sel := True;
    end;
    //------------------------------------------------
    if selType = TSelRegType.srtPosled then begin
      r := selRegsStart.reg;
      ARow := reg;
      if reg < selRegsStart.reg then begin
        r := ARow;
        ARow := selRegsStart.reg;
      end;
      for i := r to ARow do
        selRegs.Add(i);
    end else
    //------------------------------------------------
    if selType=TSelRegType.srtRect then begin
      i :=  selRegsStart.reg div fmGrid.Cols;
      //ARow :=  RegAddr div fmGrid.Cols;
      if i>ARow then begin
        r := i;
        i := ARow;
        ARow := r;
      end;
      col := (selRegsStart.reg mod fmGrid.Cols);
      //ACol := (RegAddr mod fmGrid.Cols)-1;
      if col>ACol then begin
        r := col;
        col := ACol;
        ACol := r;
      end;
      for i:=i to ARow do begin
        r := (fmGrid.Cols) * i;
        for j:=col to ACol do begin
          selRegs.Add(r + j);
        end;
      end;
    end;
    //------------------------------------------------
    fmGrid.Grid.Repaint;
    //------------------------------------------------
  end;
  RegAddrInChange := True;
  RefreshAddr(reg);
  RegAddrInChange := False;
end;


procedure TfmMapRegs.OnGridKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var reg, r, col, row: Integer;
  Refresh: Boolean;
begin
  //Memo1.Lines.Add( format('down %d >%s<', [Key, KeyChar]) );
  Refresh := True;
  reg := RegAddr;
  r := reg;
  case Key of
    vkReturn:
      begin
        if Assigned(evntEditRegAddr) then
          evntEditRegAddr(RegAddr, AddrToString(RegAddr));
      end;
    vkLeft:
      begin
        if reg>0 then Dec(reg);
      end;
    vkRight:
      begin
        if reg<65535 then Inc(reg);
      end;
    vkUp:
      begin
        if [ssCtrl] = Shift then
          fmGrid.Grid.ScrollBy(0, fmGrid.Grid.RowHeight)
        else begin
          Dec(r, fmGrid.Cols);
          if r>=0 then reg := r;
        end;
      end;
    vkDown:
      begin
        if [ssCtrl] = Shift then
          fmGrid.Grid.ScrollBy(0, -fmGrid.Grid.RowHeight)
        else begin
          Inc(r, fmGrid.Cols);
          if r<65536 then reg := r;
        end;
      end;
    vkPrior://PageUp
      begin
        if [ssCtrl] = Shift then
          fmGrid.Grid.ScrollBy(0, fmGrid.Grid.RowHeight * Max(fmGrid.Grid.VisibleRows-2, 0) )
        else begin
          Dec(r, fmGrid.Cols * (fmGrid.Grid.VisibleRows-1));
          if r<0 then begin
            reg := (reg mod (fmGrid.Cols));
          end else
            reg := r;
        end;
      end;
    vkNext://PageDown
      begin
        if [ssCtrl] = Shift then
          fmGrid.Grid.ScrollBy(0, -fmGrid.Grid.RowHeight * Max(fmGrid.Grid.VisibleRows-2,0) )
        else begin
          Inc(r, fmGrid.Cols * (fmGrid.Grid.VisibleRows-1));
          if r>65535 then begin
            col :=     r mod (fmGrid.Cols);
            row := 65535 div (fmGrid.Cols);
            if (65535 mod (fmGrid.Cols))<col then begin
              Dec(row)
            end;
            reg := col + row*fmGrid.Cols;
          end else
            reg := r;
        end;
      end;
    vkHome:
      begin
        if ssCtrl in Shift then
          reg := 0
        else
          reg := reg - (reg mod fmGrid.Cols)
      end;
    vkEnd:
      begin
        if ssCtrl in Shift then
          reg := 65535
        else
          reg := reg + (fmGrid.Cols - (reg mod fmGrid.Cols) - 1)
      end;
    else
      Refresh := False;
  end;
  if not Refresh then exit;
  if reg=RegAddr then exit;

  col := reg mod (fmGrid.Cols);
  row := reg div (fmGrid.Cols);
  if ssShift in Shift then begin
    MultiSelect(col, row, TSelRegType.srtPosled);
  end else
  if ssAlt in Shift then begin
    MultiSelect(col, row, TSelRegType.srtRect);
  end else
    MultiSelect(col, row, TSelRegType.srtOne);
end;

//procedure TfmMapRegs.OnGridKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
//begin
////  if not(ssShift in Shift)and(selRegsStart.selType=srtPosled) or
////    not(ssAlt in Shift)and(selRegsStart.selType=srtRect) then
////    selRegsStart.selType := srtNone
//end;

procedure TfmMapRegs.fmGridGridCellDblClick(const Column: TColumn; const Row: Integer);
begin
  //Column.Index + Row * fmGrid.Cols;
  if Assigned(evntEditRegAddr) then
    evntEditRegAddr(RegAddr, AddrToString(RegAddr));
end;

procedure TfmMapRegs.OnGridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var ACol, ARow, reg :Integer;
begin
//  if selRegsStart.selType<>srtNone then begin
//    if Grid.CellByPoint(x, y, ACol, ARow) then begin
//      MultiSelect(ACol, ARow);
//    end;
//  end;
  if fmGrid.Grid.CellByPoint(x, y, ACol, ARow) then begin
    begin
      reg := ACol + (fmGrid.Cols )*ARow;
      if reg<65536 then begin
        //-------------
        if (ssShift in Shift) then begin
          MultiSelect(ACol, ARow, TSelRegType.srtPosled);
        end else
        if (ssAlt in Shift) then begin
          MultiSelect(ACol, ARow, TSelRegType.srtRect);
        end else begin
          MultiSelect(ACol, ARow, TSelRegType.srtOne);
//          RegAddrInChange := True;
//          RefreshAddr(reg);
//          RegAddrInChange := True;
        end;
        //-------------
      end;
    end;
  end;
end;

//procedure TfmMapRegs.OnGridMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
//begin
////  selRegsStart.selType := srtNone;
//end;

//procedure TfrmMapReg.OnGridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
//begin
//end;


procedure TfmMapRegs.MenuItem_CheckSelClick(Sender: TObject);
var r: UInt16;
begin
  if selRegs.Count=0 then
    chkRegs.Add(RegAddr)
  else begin
    for r in selRegs do
      if not chkRegs.Contains(r) then
        chkRegs.Add(r);
  end;
  fmGrid.Grid.repaint;
end;

procedure TfmMapRegs.MenuItem_UnCheckSelClick(Sender: TObject);
var r: UInt16;
begin
  if(chkRegs.Count=0)then Exit;
  if selRegs.Count=0 then
    chkRegs.Remove(RegAddr)
  else begin
    for r in selRegs do
      chkRegs.Remove(r);
  end;
  fmGrid.Grid.repaint;
end;

procedure TfmMapRegs.MenuItem_UnCheckAllClick(Sender: TObject);
begin
  if(chkRegs.Count=0)then Exit;
  chkRegs.Clear;
  fmGrid.Grid.repaint;
end;

end.

