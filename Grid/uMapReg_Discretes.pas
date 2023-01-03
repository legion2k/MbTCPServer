unit uMapReg_Discretes;

interface

uses
  uMbRegs,
  //System.Generics.Collections,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.ListBox, FMX.Layouts,
  FMX.Controls.Presentation, uMapRegs;

type
  TfrmMapReg_Descrites = class(TFrame)
    PanelBottom: TPanel;
    LayoutRmLevel: TLayout;
    Edit_RegViewStyle: TComboBox;
    Label16: TLabel;
    ListBoxItem1: TListBoxItem;
    ListBoxItem2: TListBoxItem;
    ListBoxItem3: TListBoxItem;
    ListBoxItem4: TListBoxItem;
    ListBoxItem5: TListBoxItem;
    ListBoxItem6: TListBoxItem;
    ListBoxItem7: TListBoxItem;
    ListBoxItem8: TListBoxItem;
    fmMapRegs: TfmMapRegs;
    procedure Edit_RegViewStyleChange(Sender: TObject);
  private
    //FFuncGetDiscrets: TFuncGetDiscrets;
    //FProcSetDiscrets: TProcSetDiscrets;
    getDiscret:  TFuncGetDiscret;
    setDiscret:  TProcSetDiscret;
    procedure OnGetRegText(const ARegAddr: UInt16; out Text: string);
    procedure OnEditReg(const ARegAddr: UInt16; const sRegAddr: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property FuncGetDiscret: TFuncGetDiscret read getDiscret write getDiscret;
    property ProcSetDiscret: TProcSetDiscret read setDiscret write setDiscret;
  end;

implementation

{$R *.fmx}

uses uTools;

{ TfrmMapReg_Descrites }

constructor TfrmMapReg_Descrites.Create(AOwner: TComponent);
begin
  inherited;
  fmMapRegs.OnGetRegText := OnGetRegText;
  fmMapRegs.OnEditReg    := OnEditReg;
end;

destructor TfrmMapReg_Descrites.Destroy;
begin
  inherited;
end;

procedure TfrmMapReg_Descrites.OnGetRegText(const ARegAddr: UInt16; out Text: string);
begin
  case Edit_RegViewStyle.ItemIndex of
    0: Text := Tools.iff<string>(getDiscret(ARegAddr), 'Правда', 'Ложь');
    1: Text := Tools.iff<string>(getDiscret(ARegAddr), 'TRUE', 'FLASE');
    2: Text := Tools.iff<string>(getDiscret(ARegAddr), 'Да', 'Нет');
    3: Text := Tools.iff<string>(getDiscret(ARegAddr), 'Yes', 'Nо');
    4: Text := Tools.iff<string>(getDiscret(ARegAddr), '+', '-');
    //5:
    6: Text := Tools.iff<string>(getDiscret(ARegAddr), '1', '');
    7: Text := Tools.iff<string>(getDiscret(ARegAddr), '', '0');
  else// он же 5
    Text := Tools.iff<string>(getDiscret(ARegAddr), '1', '0');
  end
end;

procedure TfrmMapReg_Descrites.Edit_RegViewStyleChange(Sender: TObject);
begin
  fmMapRegs.fmGrid.Grid.repaint;
end;

procedure TfrmMapReg_Descrites.OnEditReg(const ARegAddr: UInt16; const sRegAddr: string);
begin
  setDiscret(not getDiscret(ARegAddr), ARegAddr);
  fmMapRegs.fmGrid.Grid.repaint;
end;

end.
