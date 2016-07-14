{== License ==
- "Summer for Delphi" by Jorge L. Cangas <jorge.cangas@gmail.com> is licensed under CC BY 4.0
-  Summer for Delphi - http://github.com/jcangas/Summer
-  Summer - Copyright(c) Jorge L. Cangas, Some rights reserved.
-  Your reuse is governed by the Creative Commons Attribution 4.0 License http://creativecommons.org/licenses/by/4.0/
}

unit Summer.Queryable;

interface

uses
  System.Generics.Collections,
  System.SysUtils;

type
  TQueryable<T> = record
  private
    FSource: TEnumerator<T>;
  public
    class operator Implicit(Enumerable: TEnumerable<T>): TQueryable<T>;
    function GetEnumerator: TEnumerator<T>;
    function ToArray: TArray<T>;
    function Where(const Filter: TPredicate<T>): TQueryable<T>;
    function Map<TResult>(Mapper: TFunc<T, TResult>): TQueryable<TResult>;
  end;

  TChainedEnumerator<T> = class(TEnumerator<T>)
  private
    FSource: TEnumerator<T>;
  protected
    function DoGetCurrent: T; override;
    function DoMoveNext: Boolean; override;
  public
    constructor Create(Source: TEnumerator<T>);
    destructor Destroy; override;
  end;

  TWhereEnumerator<T> = class(TChainedEnumerator<T>)
  private
    FFilter: TPredicate<T>;
  protected
    function DoMoveNext: Boolean; override;
  public
    constructor Create(Source: TEnumerator<T>; Filter: TPredicate<T>);
  end;

  TMapEnumerator<T, TResult> = class(TEnumerator<TResult>)
  private
    FSource: TEnumerator<T>;
    FMapper: TFunc<T, TResult>;
  protected
    function DoGetCurrent: TResult; override;
    function DoMoveNext: Boolean; override;
  public
    constructor Create(Source: TEnumerator<T>; Mapper: TFunc<T, TResult>);
    destructor Destroy; override;
  end;

implementation

{ TQueryable<T> }

function TQueryable<T>.GetEnumerator: TEnumerator<T>;
begin
  Result := FSource;
end;

class operator TQueryable<T>.Implicit(Enumerable: TEnumerable<T>): TQueryable<T>;
begin
  Result.FSource := Enumerable.GetEnumerator;
end;

function TQueryable<T>.ToArray: TArray<T>;
var
  Buf: TList<T>;
  x: T;
begin
  Buf := TList<T>.Create;
  try
    for x in Self do
      Buf.Add(x);
    Result := Buf.ToArray;
  finally
    Buf.Free;
  end;
end;

function TQueryable<T>.Map<TResult>(Mapper: TFunc<T, TResult>): TQueryable<TResult>;
begin
  Result.FSource := TMapEnumerator<T, TResult>.Create(GetEnumerator, Mapper);
end;

function TQueryable<T>.Where(const Filter: TPredicate<T>): TQueryable<T>;
begin
  Result.FSource := TWhereEnumerator<T>.Create(GetEnumerator, Filter);
end;

{ TChainedEnumerator<T> }

constructor TChainedEnumerator<T>.Create(Source: TEnumerator<T>);
begin
  inherited Create;
  FSource := Source;
end;

destructor TChainedEnumerator<T>.Destroy;
begin
  FSource.Free;
  inherited;
end;

function TChainedEnumerator<T>.DoGetCurrent: T;
begin
  Result := FSource.Current
end;

function TChainedEnumerator<T>.DoMoveNext: Boolean;
begin
  Result := FSource.MoveNext;
end;

{ TWhereEnumerator<T> }

constructor TWhereEnumerator<T>.Create(Source: TEnumerator<T>; Filter: TPredicate<T>);
begin
  inherited Create(Source);
  FFilter := Filter;
end;

function TWhereEnumerator<T>.DoMoveNext: Boolean;
begin
  Result := False;
  while not Result and inherited do
    Result := FFilter(Current);
end;

{ TMapEnumerator<T, TResult> }

constructor TMapEnumerator<T, TResult>.Create(Source: TEnumerator<T>; Mapper: TFunc<T, TResult>);
begin
  inherited Create;
  FSource := Source;
  FMapper := Mapper;
end;

destructor TMapEnumerator<T, TResult>.Destroy;
begin
  FSource.Free;
  inherited;
end;

function TMapEnumerator<T, TResult>.DoGetCurrent: TResult;
begin
  Result := FMapper(FSource.Current);
end;

function TMapEnumerator<T, TResult>.DoMoveNext: Boolean;
begin
  Result := FSource.MoveNext;
end;

end.
