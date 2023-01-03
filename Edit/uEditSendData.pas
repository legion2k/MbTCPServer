unit uEditSendData;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit;

type
  TfmEditSendData = class(TFrame)
    Edit: TEdit;
    procedure EditChangeTracking(Sender: TObject);
  private
    { Private declarations }
    _val: AnsiString;
  public
    { Public declarations }
    property Value: AnsiString read _val;
  end;

implementation
uses System.RegularExpressions;

{$R *.fmx}

type
  AnsiWin1251 = type AnsiString(1251);

procedure TfmEditSendData.EditChangeTracking(Sender: TObject);
var
  reFullWrap, reMinWrap, reNoneHex, reHex, reDoubleWrpSmbl: TRegEx;
  m: TMatchCollection;
  m2,m3: TMatch;
  dig: string;
  i: Integer;
  Data: string;
begin
  //-------------------------
  Data := Edit.Text;
  //-------------------------
  // ищет строку, начинающуюся с нечетного количества '[' из заканчивающуюся на ']'
  reFullWrap := TRegEx.Create('(?<!\[)(\[{2})*\[(?!\[).*?\]');
  // в найденной строке(после reFullWrap), ищет, непосредственно, строку '[ кикие-то символы ]'
  reMinWrap := TRegEx.Create('\[(?!\[).*?]');
  // в найденной строке(после reMinWrap), удаляет все симолы не относящиеся к HEX
  reNoneHex := TRegEx.Create('(?i)[^abcdef\d]');
  // в полученной строке(после reNoneHex), производит группировка символов парно, а если у последнего символа нет пары, то он идет один
  reHex := TRegEx.Create('(?i)[abcdef\d]{2}|[abcdef\d]');
  // заменяет в итоговом
  reDoubleWrpSmbl := TRegEx.Create('\[\[');
  // ---------
  // ищет все строки, начинающуюся с нечетного количества '[' из заканчивающуюся на ']'
  m := reFullWrap.Matches(Data);
  for i := m.Count - 1 downto 0 do
  begin
    // в найденной строке, ищем, непосредственно, подстроку '[кикие-то символы]'
    m2 := reMinWrap.Match(m[i].Value);
    dig := '';
    // в найденной подстроку, удаляет все симолы не относящиеся к HEX и группируем симолы Hex
    for m3 in reHex.Matches(reNoneHex.Replace(m2.Value, '')) do
      // преодразовываем в код
      dig := dig + AnsiChar(StrToUInt('$' + m3.Value));
    // формируем новую подстраку
    dig := Copy(m[i].Value, 1, m2.Index - 1) + dig;
    // формируем строку
    Data := Copy(Data, 1, m[i].Index - 1) + dig + Copy(Data, m[i].Index + m[i].Length, Length(Data) - (m[i].Index + m[i].Length) + 1);
  end;
  Data := reDoubleWrpSmbl.Replace(Data, '[');
  _val := AnsiWin1251(Data);
end;

end.
