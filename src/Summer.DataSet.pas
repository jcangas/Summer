{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.DataSet;

interface

uses
  Data.DB,
  System.JSON;

type
  TDataSetHelper = class Helper for TDataSet
  public
    function ToJSON: TJSONObject;
  end;

implementation

uses
  Summer.JSON;

{ TDataSetHelper }

function TDataSetHelper.ToJSON: TJSONObject;
begin
  if Self = nil then
     Result := nil
  else
     Result := TJSON.DataSetToJSON(Self);
end;

end.
