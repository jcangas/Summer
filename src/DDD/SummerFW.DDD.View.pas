unit SummerFW.DDD.View;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Data.Bind.Components, Data.Bind.ObjectScope, FMX.Layouts, System.Actions,
  FMX.ActnList, Data.Bind.EngExt, Fmx.Bind.DBEngExt, FMX.Objects;

type
  TCoreView = class(TForm)
    Layout: TLayout;
    ActionList: TActionList;
    BindSource: TAdapterBindSource;
    PrototypeModel: TDataGeneratorAdapter;
    BindingsList: TBindingsList;
  private
  public
    procedure ReportViewStateMsg(const Text: string);virtual;
  end;

implementation

{$R *.fmx}

{ TCoreView }

procedure TCoreView.ReportViewStateMsg(const Text: string);
var
  Target: TComponent;
begin
  Target := FindComponent('ViewStateMsgCtl');
  if Target is TTextControl then
    TTextControl(Target).Text := Text;
end;

end.
