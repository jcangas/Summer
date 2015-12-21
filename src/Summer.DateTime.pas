{
  Summer Framework for Delphi http://github.com/jcangas/SummerFW4D
  SummerFW4D by Jorge L. Cangas <jorge.cangas@gmail.com>
  SummerFW4D - Copyright(c) Jorge L. Cangas, Some rights reserved.
  Your reuse is governed by the Creative Commons Attribution 3.0 License
  ----
  Unit BASE: https://github.com/colinj/TDateTimeHelper/blob/master/DateTimeHelper.pas
}
unit Summer.DateTime;

interface

uses
  System.SysUtils,
  System.Types,
  System.DateUtils;

type
  TTimeHelper = record helper for TTime
  public
    class function Create(const aHour, aMinute, aSecond, aMillisecond: Word): TTime; overload; static; inline;

    function ToString(const aFormatStr: string = ''): string; inline;

    function ToJSON: string;
    function FromJSON(Value: string): TTime;
  end;

  TDateHelper = record helper for TDate
  public
    class function Create(const aYear, aMonth, aDay: Word): TDate; overload; static; inline;

    function ToString(const aFormatStr: string = ''): string; inline;

    function ToJSON: string;
    function FromJSON(Value: string): TDate;
  end;

  TDateTimeHelper = record helper for TDateTime
  private
    function GetDay: Word; //inline;
    function GetDate: TDate; //inline;
    function GetDayOfWeek: Word; //inline;
    function GetDayOfYear: Word; //inline;
    function GetHour: Word; //inline;
    function GetMillisecond: Word; //inline;
    function GetMinute: Word; //inline;
    function GetMonth: Word; //inline;
    function GetSecond: Word; //inline;
    function GetTime: TTime; //inline;
    function GetYear: Integer; //inline;
    class function GetNow: TDateTime; static; //inline;
    class function GetToday: TDateTime; static; //inline;
    class function GetTomorrow: TDateTime; static; //inline;
    class function GetYesterDay: TDateTime; static; //inline;
  public
    class function Create(const aYear, aMonth, aDay: Word): TDateTime; overload; static; //inline;
    class function Create(const aYear, aMonth, aDay, aHour, aMinute, aSecond, aMillisecond: Word): TDateTime; overload; static; //inline;

    class property Now: TDateTime read GetNow;
    class property Today: TDateTime read GetToday;
    class property Yesterday: TDateTime read GetYesterDay;
    class property Tomorrow: TDateTime read GetTomorrow;

    property Date: TDate read GetDate;
    property Time: TTime read GetTime;

    property DayOfWeek: Word read GetDayOfWeek;
    property DayOfYear: Word read GetDayOfYear;

    property Year: Integer read GetYear;
    property Month: Word read GetMonth;
    property Day: Word read GetDay;
    property Hour: Word read GetHour;
    property Minute: Word read GetMinute;
    property Second: Word read GetSecond;
    property Millisecond: Word read GetMillisecond;

    function ToString(const aFormatStr: string = ''): string; //inline;

    function ToJSON: string;
    function FromJSON(Value: string): TDateTime;

    function StartOfYear: TDateTime; //inline;
    function EndOfYear: TDateTime; //inline;
    function StartOfMonth: TDateTime; //inline;
    function EndOfMonth: TDateTime; //inline;
    function StartOfWeek: TDateTime; //inline;
    function EndOfWeek: TDateTime; //inline;
    function StartOfDay: TDateTime; //inline;
    function EndOfDay: TDateTime; //inline;

    function AddYears(const aNumberOfYears: Integer = 1): TDateTime; //inline;
    function AddMonths(const aNumberOfMonths: Integer = 1): TDateTime; //inline;
    function AddDays(const aNumberOfDays: Integer = 1): TDateTime; //inline;
    function AddHours(const aNumberOfHours: Int64 = 1): TDateTime; //inline;
    function AddMinutes(const aNumberOfMinutes: Int64 = 1): TDateTime; //inline;
    function AddSeconds(const aNumberOfSeconds: Int64 = 1): TDateTime; //inline;
    function AddMilliseconds(const aNumberOfMilliseconds: Int64 = 1): TDateTime; //inline;

    function CompareTo(const aDateTime: TDateTime): TValueRelationship; //inline;
    function Equals(const aDateTime: TDateTime): Boolean; //inline;
    function IsSameDay(const aDateTime: TDateTime): Boolean; //inline;
    function InRange(const aStartDateTime, aEndDateTime: TDateTime; const aInclusive: Boolean = True): Boolean; //inline;
    function IsInLeapYear: Boolean; //inline;
    function IsToday: Boolean; //inline;
    function IsAM: Boolean; //inline;
    function IsPM: Boolean; //inline;

    function YearsBetween(const aDateTime: TDateTime): Integer; //inline;
    function MonthsBetween(const aDateTime: TDateTime): Integer; //inline;
    function WeeksBetween(const aDateTime: TDateTime): Integer; //inline;
    function DaysBetween(const aDateTime: TDateTime): Integer; //inline;
    function HoursBetween(const aDateTime: TDateTime): Int64; //inline;
    function MinutesBetween(const aDateTime: TDateTime): Int64; //inline;
    function SecondsBetween(const aDateTime: TDateTime): Int64; //inline;
    function MilliSecondsBetween(const aDateTime: TDateTime): Int64; //inline;

    function WithinYears(const aDateTime: TDateTime; const aYears: Integer): Boolean; //inline;
    function WithinMonths(const aDateTime: TDateTime; const aMonths: Integer): Boolean; //inline;
    function WithinWeeks(const aDateTime: TDateTime; const aWeeks: Integer): Boolean; //inline;
    function WithinDays(const aDateTime: TDateTime; const aDays: Integer): Boolean; //inline;
    function WithinHours(const aDateTime: TDateTime; const aHours: Int64): Boolean; //inline;
    function WithinMinutes(const aDateTime: TDateTime; const aMinutes: Int64): Boolean; //inline;
    function WithinSeconds(const aDateTime: TDateTime; const aSeconds: Int64): Boolean; //inline;
    function WithinMilliseconds(const aDateTime: TDateTime; const AMilliseconds: Int64): Boolean; //inline;
  end;

implementation

uses
  Summer.JSON;

{ TDateTimeHelper }

function TDateTimeHelper.AddDays(const aNumberOfDays: Integer): TDateTime;
begin
  Result := IncDay(Self, aNumberOfDays);
end;

function TDateTimeHelper.AddHours(const aNumberOfHours: Int64): TDateTime;
begin
  Result := IncHour(Self, aNumberOfHours);
end;

function TDateTimeHelper.AddMilliseconds(const aNumberOfMilliseconds: Int64): TDateTime;
begin
  Result := IncMilliSecond(Self, aNumberOfMilliseconds);
end;

function TDateTimeHelper.AddMinutes(const aNumberOfMinutes: Int64): TDateTime;
begin
  Result := IncMinute(Self, aNumberOfMinutes);
end;

function TDateTimeHelper.AddMonths(const aNumberOfMonths: Integer): TDateTime;
begin
  Result := IncMonth(Self, aNumberOfMonths);
end;

function TDateTimeHelper.AddSeconds(const aNumberOfSeconds: Int64): TDateTime;
begin
  Result := IncSecond(Self, aNumberOfSeconds);
end;

function TDateTimeHelper.AddYears(const aNumberOfYears: Integer): TDateTime;
begin
  Result := IncYear(Self, aNumberOfYears);
end;

function TDateTimeHelper.CompareTo(const aDateTime: TDateTime): TValueRelationship;
begin
  Result := CompareDateTime(Self, aDateTime);
end;

class function TDateTimeHelper.Create(const aYear, aMonth,
  aDay: Word): TDateTime;
begin
  Result := EncodeDate(aYear, aMonth, aDay);
end;

class function TDateTimeHelper.Create(const aYear, aMonth, aDay, aHour, aMinute, aSecond, aMillisecond: Word): TDateTime;
begin
  Result := EncodeDateTime(aYear, aMonth, aDay, aHour, aMinute, aSecond, aMillisecond);
end;

function TDateTimeHelper.DaysBetween(const aDateTime: TDateTime): Integer;
begin
  Result := System.DateUtils.DaysBetween(Self, aDateTime);
end;

function TDateTimeHelper.EndOfDay: TDateTime;
begin
  Result := EndOfTheDay(Self);
end;

function TDateTimeHelper.EndOfMonth: TDateTime;
begin
  Result := EndOfTheMonth(Self);
end;

function TDateTimeHelper.EndOfWeek: TDateTime;
begin
  Result := EndOfTheWeek(Self);
end;

function TDateTimeHelper.EndOfYear: TDateTime;
begin
  Result := EndOfTheYear(Self);
end;

function TDateTimeHelper.Equals(const aDateTime: TDateTime): Boolean;
begin
  Result := SameDateTime(Self, aDateTime);
end;

function TDateTimeHelper.GetDate: TDate;
begin
  Result := DateOf(Self);
end;

function TDateTimeHelper.GetDay: Word;
begin
  Result := DayOf(Self);
end;

function TDateTimeHelper.GetDayOfWeek: Word;
begin
  Result := DayOfTheWeek(Self);
end;

function TDateTimeHelper.GetDayOfYear: Word;
begin
  Result := DayOfTheYear(Self);
end;

function TDateTimeHelper.GetHour: Word;
begin
  Result := HourOf(Self);
end;

function TDateTimeHelper.GetMillisecond: Word;
begin
  Result := MilliSecondOf(Self);
end;

function TDateTimeHelper.GetMinute: Word;
begin
  Result := MinuteOf(Self);
end;

function TDateTimeHelper.GetMonth: Word;
begin
  Result := MonthOf(Self);
end;

class function TDateTimeHelper.GetNow: TDateTime;
begin
  Result := System.SysUtils.Now;
end;

function TDateTimeHelper.GetSecond: Word;
begin
  Result := SecondOf(Self);
end;

function TDateTimeHelper.GetTime: TTime;
begin
  Result := TimeOf(Self);
end;

class function TDateTimeHelper.GetToday: TDateTime;
begin
  Result := System.SysUtils.Date;
end;

class function TDateTimeHelper.GetTomorrow: TDateTime;
begin
  Result := System.SysUtils.Date + 1;
end;

function TDateTimeHelper.GetYear: Integer;
begin
  Result := YearOf(Self);
end;

class function TDateTimeHelper.GetYesterDay: TDateTime;
begin
  Result := System.SysUtils.Date - 1;
end;

function TDateTimeHelper.HoursBetween(const aDateTime: TDateTime): Int64;
begin
  Result := System.DateUtils.HoursBetween(Self, aDateTime);
end;

function TDateTimeHelper.InRange(const aStartDateTime, aEndDateTime: TDateTime; const aInclusive: Boolean): Boolean;
begin
  Result := DateTimeInRange(Self, aStartDateTime, aEndDateTime, aInclusive);
end;

function TDateTimeHelper.IsAM: Boolean;
begin
  Result := System.DateUtils.IsAM(Self);
end;

function TDateTimeHelper.IsInLeapYear: Boolean;
begin
  Result := System.DateUtils.IsInLeapYear(Self);
end;

function TDateTimeHelper.IsPM: Boolean;
begin
  Result := System.DateUtils.IsPM(Self);
end;

function TDateTimeHelper.IsSameDay(const aDateTime: TDateTime): Boolean;
begin
  Result := System.DateUtils.IsSameDay(Self, aDateTime);
end;

function TDateTimeHelper.IsToday: Boolean;
begin
  Result := System.DateUtils.IsToday(Self);
end;

function TDateTimeHelper.MilliSecondsBetween(const aDateTime: TDateTime): Int64;
begin
  Result := System.DateUtils.MilliSecondsBetween(Self, aDateTime);
end;

function TDateTimeHelper.MinutesBetween(const aDateTime: TDateTime): Int64;
begin
  Result := System.DateUtils.MinutesBetween(Self, aDateTime);
end;

function TDateTimeHelper.MonthsBetween(const aDateTime: TDateTime): Integer;
begin
  Result := System.DateUtils.MonthsBetween(Self, aDateTime);
end;

function TDateTimeHelper.SecondsBetween(const aDateTime: TDateTime): Int64;
begin
  Result := System.DateUtils.SecondsBetween(Self, aDateTime);
end;

function TDateTimeHelper.StartOfDay: TDateTime;
begin
  Result := StartOfTheDay(Self);
end;

function TDateTimeHelper.StartOfMonth: TDateTime;
begin
  Result := StartOfTheMonth(Self);
end;

function TDateTimeHelper.StartOfWeek: TDateTime;
begin
  Result := StartOfTheWeek(Self);
end;

function TDateTimeHelper.StartOfYear: TDateTime;
begin
  Result := StartOfTheYear(Self);
end;

function TDateTimeHelper.ToString(const aFormatStr: string): string;
begin
  if aFormatStr = '' then
    Result := DateToStr(Self)
  else
    Result := FormatDateTime(aFormatStr, Self);
end;

function TDateTimeHelper.WeeksBetween(const aDateTime: TDateTime): Integer;
begin
  Result := System.DateUtils.WeeksBetween(Self, aDateTime);
end;

function TDateTimeHelper.WithinDays(const aDateTime: TDateTime; const aDays: Integer): Boolean;
begin
  Result := System.DateUtils.WithinPastDays(Self, aDateTime, aDays);
end;

function TDateTimeHelper.WithinHours(const aDateTime: TDateTime; const aHours: Int64): Boolean;
begin
  Result := System.DateUtils.WithinPastHours(Self, aDateTime, aHours);
end;

function TDateTimeHelper.WithinMilliseconds(const aDateTime: TDateTime; const AMilliseconds: Int64): Boolean;
begin
  Result := System.DateUtils.WithinPastMilliSeconds(Self, aDateTime, AMilliseconds);
end;

function TDateTimeHelper.WithinMinutes(const aDateTime: TDateTime; const aMinutes: Int64): Boolean;
begin
  Result := System.DateUtils.WithinPastMinutes(Self, aDateTime, aMinutes);
end;

function TDateTimeHelper.WithinMonths(const aDateTime: TDateTime; const aMonths: Integer): Boolean;
begin
  Result := System.DateUtils.WithinPastMonths(Self, aDateTime, aMonths);
end;

function TDateTimeHelper.WithinSeconds(const aDateTime: TDateTime; const aSeconds: Int64): Boolean;
begin
  Result := System.DateUtils.WithinPastSeconds(Self, aDateTime, aSeconds);
end;

function TDateTimeHelper.WithinWeeks(const aDateTime: TDateTime; const aWeeks: Integer): Boolean;
begin
  Result := System.DateUtils.WithinPastWeeks(Self, aDateTime, aWeeks);
end;

function TDateTimeHelper.WithinYears(const aDateTime: TDateTime; const aYears: Integer): Boolean;
begin
  Result := System.DateUtils.WithinPastYears(Self, aDateTime, aYears);
end;

function TDateTimeHelper.YearsBetween(const aDateTime: TDateTime): Integer;
begin
  Result := System.DateUtils.YearsBetween(Self, aDateTime);
end;

function TDateTimeHelper.ToJSON: string;
begin
  Result := TJSON.DateTimeToJSON(Self, TJSON.DateTimeFormat.Simple);
end;

function TDateTimeHelper.FromJSON(Value: string): TDateTime;
begin
  Result := TJSON.DateTimeFromJSON(Value, True);
end;

{ TDateHelper }

class function TDateHelper.Create(const aYear, aMonth, aDay: Word): TDate;
begin
  Result := EncodeDate(aYear, aMonth, aDay);
end;

function TDateHelper.ToString(const aFormatStr: string): string;
begin
  if aFormatStr = '' then
    Result := DateToStr(Self)
  else
    Result := FormatDateTime(aFormatStr, Self);
end;

function TDateHelper.ToJSON: string;
begin
  Result := TJSON.DateToJSON(Self);
end;

function TDateHelper.FromJSON(Value: string): TDate;
begin
  Result := TJSON.DateFromJSON(Value);
end;

{ TTimeHelper }

class function TTimeHelper.Create(const aHour, aMinute, aSecond, aMillisecond: Word): TTime;
begin
  Result := EncodeTime(aHour, aMinute, aSecond, aMillisecond);
end;

function TTimeHelper.ToString(const aFormatStr: string): string;
begin
  if aFormatStr = '' then
    Result := DateToStr(Self)
  else
    Result := FormatDateTime(aFormatStr, Self);
end;

function TTimeHelper.ToJSON: string;
begin
  Result := TJSON.TimeToJSON(Self);
end;

function TTimeHelper.FromJSON(Value: string): TTime;
begin
  Result := TJSON.TimeFromJSON(Value, True);
end;

end.
