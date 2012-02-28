{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
}

unit SummerFW.Utils.Rules;

interface
uses Classes,SysUtils,  Generics.Collections, RegularExpressions;

type
  TRuleTrigger = (
    rtBeforeApplyInsert, rtAfterApplyInsert,
    rtBeforeApplyUpdate, rtAfterApplyUpdate,
    rtBeforeApplyDelete, rtAfterApplyDelete,
    rtOnValidateField,
    rtOnNewRecord,
    rtOnCompleteRecord,
    rtOnValidateRecord,
    rtOnDefaultValue
  );

  TRuleTrigers = set of TRuleTrigger;
  TRuleClass = class of TRule;
  TRule = class
  private
    FSubjectMask: string;
    FTriggers: TRuleTrigers;
    FErrorMessage: string;
  protected
    function GetRuleName: string;virtual;
    function GetErrorMessage(Target: TObject): string;virtual;
    function DoSatisfiedBy(Target: TObject): Boolean;virtual;abstract;
  public
    type TMatchKind = (mkRegExpr, mkString);
    constructor Create(SubjectMask: string; Triggers: TRuleTrigers; MatchKind: TMatchKind);
    function Match(Subject: string; Trigger: TRuleTrigger): Boolean;

    procedure BeginUse(Target: TObject);virtual;
    function Enabled(Target: TObject): Boolean;virtual;
    function SatisfiedBy(Target: TObject): Boolean;
    procedure EndUse(Target: TObject);virtual;

    property ErrorMessage: string read FErrorMessage;
    property RuleName: string read GetRuleName;
    property SubjectMask: string read FSubjectMask;
    property Triggers: TRuleTrigers read FTriggers;
  end;
  TRuleList = TObjectList<TRule>;

  TRuleEngine = class
  type
    TRegistry = TRuleList;
    TErrorInfo = class
    private
      FRule: TRule;
      FTarget: TObject;
      FMessage: string;
    public
      constructor Create(Rule: TRule; Target: TObject; Msg: string);
      function ToString: string;override;
      property Rule: TRule read FRule;
      property Target: TObject read FTarget;
      property Message: string read FMessage;
    end;

    TErrorInfos = class(TObjectList<TErrorInfo>)
    public
      function ToString: string;override;
    end;
  private
    FRegistry: TRegistry;
  public
    constructor Create;
    destructor Destroy; override;
    function Register(RuleClass: TRuleClass; SubjectMask: string; Triggers: TRuleTrigers; MatchKind: TRule.TMatchKind = mkRegExpr): TRuleEngine;
    function Satisfy(Subject: string; ForTrigger: TRuleTrigger; ATarget: TObject; out Errors: TErrorInfos): Boolean;overload;
    function Satisfy(SubjectFmt: string; Args: array of const; ForTrigger: TRuleTrigger; ATarget: TObject; out Errors: TErrorInfos): Boolean;overload;
  end;

implementation

uses StrUtils, DB;

{ TRule }

procedure TRule.BeginUse(Target: TObject);
begin

end;

procedure TRule.EndUse(Target: TObject);
begin

end;

constructor TRule.Create(SubjectMask: string; Triggers: TRuleTrigers; MatchKind: TMatchKind);
begin
  inherited Create;
  if MatchKind = mkString then
    SubjectMask := TRegEx.Escape(SubjectMask);
  FSubjectMask := SubjectMask;
  FTriggers := Triggers;
end;

function TRule.Enabled(Target: TObject): Boolean;
begin
  Result := True;
end;

function TRule.GetErrorMessage(Target: TObject): string;
begin
  Result := Format('Rule %s failed for target %s', [RuleName, Target.ToString])
end;

function TRule.GetRuleName: string;
begin
  Result := ClassName;
  if AnsiStartsText('T', Result) then
    System.Delete(Result, 1, 1); // Remove 'T' prefix
  if AnsiEndsText('Rule', Result) then // Remove 'Rule' sufix
    System.Delete(Result, Length(Result) - 3, 4);
end;

function TRule.Match(Subject: string; Trigger: TRuleTrigger): Boolean;
begin
  Result := (Trigger in Triggers) and TRegEx.IsMatch(Subject, FSubjectMask)
end;

function TRule.SatisfiedBy(Target: TObject): Boolean;
begin
  FErrorMessage := '';
  Result := DoSatisfiedBy(Target);
  if not Result then
    FErrorMessage := GetErrorMessage(Target);
end;

{ TRuleEngine }

function TRuleEngine.Satisfy(Subject: string; ForTrigger: TRuleTrigger; ATarget: TObject;
  out Errors: TErrorInfos): Boolean;
var
  Rule: TRule;
begin
  Errors := nil;
  for Rule in FRegistry do begin
    if not Rule.Match(Subject, ForTrigger) then Continue;
    try
      Rule.BeginUse(ATarget);
      if not Rule.Enabled(ATarget) then Continue;
      if Rule.SatisfiedBy(ATarget) then Continue;
      if not Assigned(Errors) then
        Errors := TErrorInfos.Create;
      Errors.Add(TErrorInfo.Create(Rule, ATarget, Rule.ErrorMessage));
    finally
      Rule.EndUse(ATarget);
    end;
  end;
  Result := not Assigned(Errors);
end;

constructor TRuleEngine.Create;
begin
  inherited Create;
  FRegistry := TRegistry.Create(True);
end;

destructor TRuleEngine.Destroy;
begin
  FRegistry.Free;
  inherited;
end;

function TRuleEngine.Register(RuleClass: TRuleClass; SubjectMask: string;
  Triggers: TRuleTrigers; MatchKind: TRule.TMatchKind): TRuleEngine;
begin
  Result := Self;
  FRegistry.Add(RuleClass.Create(SubjectMask, Triggers, MatchKind));
end;

function TRuleEngine.Satisfy(SubjectFmt: string; Args: array of const;
  ForTrigger: TRuleTrigger; ATarget: TObject; out Errors: TErrorInfos): Boolean;
begin
  Result := Satisfy(Format(SubjectFmt, Args),ForTrigger, ATarget, Errors);
end;

{ TRuleEngine.TRuleErrorInfo }

constructor TRuleEngine.TErrorInfo.Create(Rule: TRule; Target: TObject;
  Msg: string);
begin
  inherited Create;
  FRule := Rule;
  FTarget := Target;
  FMessage := Msg;
end;

function TRuleEngine.TErrorInfo.ToString: string;
begin
  Result := Message;
end;

{ TRuleEngine.TRuleErrorInfoList }

function TRuleEngine.TErrorInfos.ToString: string;
var
  EI: TErrorInfo;
begin
  with TStringBuilder.Create do begin
    for EI in Self do
      AppendLine(EI.Message);
    Result := ToString;
    Free;
  end;
end;

end.
