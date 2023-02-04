unit uIniJSON;

interface

uses System.JSON;

type

  TIniJSONFile = class
  private
    type
      TFuncToString<T> = reference to function(const v: T): string;
    var
    _fileName: string;
    JSON: TJSONObject;
    _needWrite: Boolean;
    procedure _setValue(const APath: string; const AValue: TJSONValue);
  public
    constructor Create(AFileName: string);
    destructor Destroy; override;
    function getValue<T>(const APath: string; ADefValue: T):T;
    procedure setValue(const APath: string; const AValue: string); overload;
    procedure setValue(const APath: string; const AValue: Int64); overload;
    procedure setValue(const APath: string; const AValue: Float64); overload;
    procedure setValue(const APath: string; const AValue: Boolean); overload;
    procedure setValue(const APath: string; const AValue: TArray<UInt32>); overload;
    procedure setValue(const APath: string; const AValue: TArray<UInt16>); overload;
    procedure setValue(const APath: string; const AValue: TArray<UInt8>); overload;
    procedure setValue(const APath: string; const AValue: TArray<Boolean>); overload;
    procedure setValue(const APath: string; const AValue: TArray<string>); overload;
  end;

implementation
uses System.IOUtils, {System.Classes, }System.SysUtils, System.Rtti;

{ TIniJSONFile }

constructor TIniJSONFile.Create(AFileName: string);
begin
  inherited Create;
  //_fileName := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetHomePath, AFileName);
  _fileName := AFileName;
  JSON := TJSONObject.Create;
  try
    if TFile.Exists(_fileName) then
      //JSON.Parse(TFile.ReadAllBytes(_fileName), 0, True);
      JSON.Parse(TEncoding.UTF8.GetBytes(TFile.ReadAllText(_fileName{, TEncoding.UTF8})), 0, True);
  except
    //empty JSON
  end;
  _needWrite := False;
end;

destructor TIniJSONFile.Destroy;
begin
  try
    if _needWrite then begin
      //var buf: TBytes;
      //SetLength(buf, JSON.EstimatedByteSize);
      //JSON.ToBytes(buf,0);
      //TFile.WriteAllBytes( _fileName, buf );
      TFile.WriteAllText( _fileName, JSON.ToString, TEncoding.UTF8);//одной строкой
      //TFile.WriteAllText( _fileName, JSON.Format(2), TEncoding.UTF8);//многострочный, с отступами
    end;
  finally
    inherited;
  end;
end;

function TIniJSONFile.getValue<T>(const APath: string; ADefValue: T): T;
begin
  if not JSON.TryGetValue<T>(APath, Result) then
    Result := ADefValue;
  //Result := JSON.GetValue<T>(APath, ADefValue);
end;

procedure TIniJSONFile._setValue(const APath: string; const AValue: TJSONValue);
var js: TJSONObject;
    sub: TJSONValue;
    pathParser: TJSONPathParser;
begin
  if APath='' then
    raise Exception.Create('Путь не задан');
  pathParser := TJSONPathParser.Create(APath);
  js := JSON;
  while not pathParser.IsEof do
    case pathParser.NextToken of
      TJSONPathParser.TToken.Name: begin
        sub := js.GetValue( pathParser.TokenName );
        if pathParser.IsEof then begin
          // если это последний в пути
          if sub=nil then begin
            js.AddPair( pathParser.TokenName, AValue );
            //Break;
          end else if sub.ClassType=TJSONObject then begin
            js.RemovePair( pathParser.TokenName );
            js.AddPair( pathParser.TokenName, AValue );
            //raise Exception.Create('Невозможно уставновить значение в структуру');
          end else begin
            js.RemovePair( pathParser.TokenName );
            js.AddPair( pathParser.TokenName, AValue );
          end;
        end else begin
          // если это не последний в пути
          if sub=nil then begin
            sub := TJSONObject.Create;
            js.AddPair( pathParser.TokenName, sub );
          end else if sub.ClassType<>TJSONObject then begin
            js.RemovePair( pathParser.TokenName );
            sub := TJSONObject.Create;
            js.AddPair( pathParser.TokenName, sub );
            //raise Exception.Create('Невозможно уставновить структуру в значение');
          end;
          js := sub as TJSONObject;
        end;
      end;
      TJSONPathParser.TToken.ArrayIndex: begin
        //i := pathParser.TokenArrayIndex;
        raise Exception.Create('Массивы не поддерживаются');
      end;
      TJSONPathParser.TToken.Error,
      TJSONPathParser.TToken.Undefined:
        Break;
      TJSONPathParser.TToken.Eof:
        ;
    end;
  _needWrite := True;
end;

procedure TIniJSONFile.setValue(const APath: string; const AValue: string);
begin
  _setValue(APath, TJSONString.Create(AValue));
end;

procedure TIniJSONFile.setValue(const APath: string; const AValue: Int64);
begin
  _setValue(APath, TJSONNumber.Create(AValue));
end;

procedure TIniJSONFile.setValue(const APath: string; const AValue: Float64);
begin
  _setValue(APath, TJSONNumber.Create(AValue));
end;

procedure TIniJSONFile.setValue(const APath: string; const AValue: Boolean);
begin
  _setValue(APath, TJSONBool.Create(AValue));
end;

procedure TIniJSONFile.setValue(const APath: string; const AValue: TArray<UInt8>);
var ar: TJSONArray;
  v: UInt8;
begin
  ar := TJSONArray.Create;
  for v in AValue do
    ar.Add(v);
  _setValue(APath, ar);
end;

procedure TIniJSONFile.setValue(const APath: string; const AValue: TArray<UInt16>);
var ar: TJSONArray;
  v: UInt16;
begin
  ar := TJSONArray.Create;
  for v in AValue do
    ar.Add(v);
  _setValue(APath, ar);
end;

procedure TIniJSONFile.setValue(const APath: string; const AValue: TArray<UInt32>);
var ar: TJSONArray;
  v: UInt32;
begin
  ar := TJSONArray.Create;
  for v in AValue do
    ar.Add(v);
  _setValue(APath, ar);
end;

procedure TIniJSONFile.setValue(const APath: string; const AValue: TArray<Boolean>);
var ar: TJSONArray;
  v: Boolean;
begin
  ar := TJSONArray.Create;
  for v in AValue do
    ar.Add(v);
  _setValue(APath, ar);
end;

procedure TIniJSONFile.setValue(const APath: string; const AValue: TArray<string>);
var ar: TJSONArray;
  v: string;
begin
  ar := TJSONArray.Create;
  for v in AValue do
    ar.Add(v);
  _setValue(APath, ar);
end;

end.
