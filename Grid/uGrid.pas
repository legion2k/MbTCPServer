unit uGrid;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, System.Rtti, FMX.Grid.Style,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Grid, System.Math.Vectors, FMX.Controls3D, FMX.Layers3D;

type
  TColumnName = procedure (Index: Integer) of object;

  TfmGrid = class(TFrame)
    GridFixCol: TGrid;
    Grid: TGrid;
    Splitter: TSplitter;
    FixCol: TStringColumn;
    procedure Grid_FixColResize(Sender: TObject);
    procedure Grid_SelectCell(Sender: TObject; const ACol, ARow: Integer; var CanSelect: Boolean);
    procedure Grid_OnResize(Sender: TObject);
    procedure Grid_FixColSelectCell(Sender: TObject; const ACol, ARow: Integer; var CanSelect: Boolean);
  private
    { Private declarations }
    _GridWidth_: Single;
    _GridDoReCountCols_: Boolean;
    _ColsCount_: Integer;
    _DefColWidth_: UInt16;
    _ColumnName_: TColumnName;
    procedure SET_Rows(const Count: Integer);
    function  GET_Rows(): Integer;
    procedure SET_Cols(const Count: Integer);
    function  GET_Cols(): Integer;
    procedure SET_DefColWidth(const Count: UInt16);
    procedure Column_OnResize(Sender: TObject);
    procedure ChangeColsCount(Sender: TColumn = nil);
    procedure Grid_OnViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
    procedure GridFix_OnViewportPositionChange(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
  public
    property ColumnName: TColumnName read _ColumnName_ write _ColumnName_;
    // ---------------------------
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // ---------------------------
    property Cols: Integer read GET_Cols write SET_Cols;
    property Rows: Integer read GET_Rows write SET_Rows;
    property DefColWidth: UInt16 read _DefColWidth_ write SET_DefColWidth;
  end;

implementation
uses System.Math;

{$R *.fmx}

{ TfmGrid }

constructor TfmGrid.Create(AOwner: TComponent);
begin
  inherited;
  _GridWidth_ := 0;
  _GridDoReCountCols_ := False;
  _DefColWidth_ := 50;
  _ColsCount_ := 0;
  Grid.ScrollToTop();
  GridFixCol.ScrollToTop();
  Grid.OnViewportPositionChange := Grid_OnViewportPositionChange;
  GridFixCol.OnViewportPositionChange := GridFix_OnViewportPositionChange;
end;

destructor TfmGrid.Destroy;
begin
  inherited;
end;

procedure TfmGrid.Grid_FixColResize(Sender: TObject);
begin
  FixCol.Width := GridFixCol.Width - 1;
end;

procedure TfmGrid.GridFix_OnViewportPositionChange(Sender: TObject; const OldViewportPosition,
  NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
begin
  Grid.OnViewportPositionChange := nil;
  Grid.BeginUpdate;
  Grid.ScrollTo(Grid.ViewportPosition.X, NewViewportPosition.Y, False);
  Grid.EndUpdate;
  Grid.OnViewportPositionChange := Grid_OnViewportPositionChange;
end;

procedure TfmGrid.Grid_OnViewportPositionChange(Sender: TObject; const OldViewportPosition,
  NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
begin
  GridFixCol.OnViewportPositionChange := nil;
  GridFixCol.BeginUpdate;
  GridFixCol.ScrollTo({Grid.ViewportPosition.X}0, NewViewportPosition.Y, False);
  GridFixCol.EndUpdate;
  GridFixCol.OnViewportPositionChange := GridFix_OnViewportPositionChange;
end;

procedure TfmGrid.Grid_FixColSelectCell(Sender: TObject; const ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := False;
end;

procedure TfmGrid.Grid_SelectCell(Sender: TObject; const ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := False;
end;

function TfmGrid.GET_Rows: Integer;
begin
  Result := Grid.RowCount;
end;

procedure TfmGrid.SET_Rows(const Count: Integer);
begin
  if GridFixCol.RowCount<>Count then begin
    GridFixCol.Model.ClearCache;
  end;
  GridFixCol.RowCount := Count+1;
  Grid.RowCount := Count;
end;

procedure TfmGrid.SET_Cols(const Count: Integer);
begin
  if _ColsCount_ <> Count then begin
    _ColsCount_ := Count;
    ChangeColsCount();
  end;
end;

function TfmGrid.GET_Cols: Integer;
begin
  Result := Grid.ColumnCount;
end;

procedure TfmGrid.SET_DefColWidth(const Count: UInt16);
var i: Integer;
begin
  _DefColWidth_ := Count;
  _GridDoReCountCols_ := True;
  Grid.BeginUpdate;
  for i:=0 to Grid.ColumnCount-1 do
    Grid.Columns[i].Width := _DefColWidth_;
  Grid.EndUpdate;
  _GridDoReCountCols_ := False;
  ChangeColsCount();
end;

procedure TfmGrid.ChangeColsCount(Sender: TColumn);
var i, colCnt: Integer;
  col: TColumn;
  w: Single;
  chngAdd, chngDel: Boolean;
begin
  if _GridDoReCountCols_ then exit;
  _GridDoReCountCols_ := True;
  //---------------------------
  if _ColsCount_=0 then begin
    colCnt := 0;
    //w := Grid.Width;
    w := Grid.ViewportSize.Width;
    for i:=0 to Cols-1 do begin
      w := w - (Grid.Columns[i].Width + 1.01{толшина линии});
      if w<=1 then
        break;
      colCnt := i+1;
    end;
    if w>1 then begin
        w := w / _DefColWidth_;
        w := Trunc(w);
        colCnt := colCnt + Trunc(w);
    end;
    if colCnt<1 then
      colCnt := 1;
  end else begin
    colCnt := {1 + }_ColsCount_;
  end;
  //---------------------------
  Grid.BeginUpdate;
  chngDel := False;
  while Grid.ColumnCount>colCnt do begin
    col := Grid.Columns[Grid.ColumnCount-1];
    if Sender=col then Break;
    col.OnResize := nil;
    Grid.RemoveObject(col);
    FreeAndNil(col);
    chngDel := True;
  end;
  chngAdd := False;
  while Grid.ColumnCount<colCnt do begin
    col := TStringColumn.Create(nil);
    col.Width := _DefColWidth_;
    col.Tag := _DefColWidth_;
    Grid.AddObject(col);
    col.OnResized := Column_OnResize;
    if Assigned(_ColumnName_) then
      _ColumnName_(Grid.ColumnCount-1);
    chngAdd := True;
  end;
  if chngAdd or chngDel then
    Rows := Ceil(65_536/(Grid.ColumnCount{-1}));
  Grid.EndUpdate;
  //---------------------------
  _GridDoReCountCols_ := False;
end;

procedure TfmGrid.Column_OnResize(Sender: TObject);
var c: TColumn;
begin
  if Sender is TColumn then begin
    c := Sender as TColumn;
    if c.Parent<>nil then
      if c.Tag<>Round(c.Width) then begin
        c.Tag := Round(c.Width);
        ChangeColsCount(Sender as TColumn);
      end;
  end;
end;

procedure TfmGrid.Grid_OnResize(Sender: TObject);
begin
  if (_GridWidth_=Grid.Width) then exit;
  _GridWidth_ := Grid.Width;
  ChangeColsCount();
end;

end.

