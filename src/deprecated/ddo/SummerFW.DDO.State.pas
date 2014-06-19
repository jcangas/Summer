unit SummerFW.DDO.State;

interface

uses TypInfo, Generics.Collections, RTTI;

type
  TStoreStateClass = class of TStoreState;

  TStoreState = class
  public
    class function MakeStoredClean: TStoreStateClass; virtual;
    class function MakeStored: TStoreStateClass; virtual;
    class function MakeUpdated: TStoreStateClass; virtual;
    class function MakeDeleted: TStoreStateClass; virtual;
    class function MakeSaved: TStoreStateClass; virtual;
    class function IsUpdated: Boolean; virtual;
    class function IsNew: Boolean; virtual;
    class function IsDeleted: Boolean; virtual;
  end;

  Transient = class(TStoreState)
  public
    class function MakeStored: TStoreStateClass; override;
  end;

  Stored = class(TStoreState)
  public
    class function MakeSaved: TStoreStateClass; override;
  end;

  StoredNew = class(Stored)
  public
    class function MakeDeleted: TStoreStateClass; override;
  end;

  StoredClean = class(Stored)
  public
    class function MakeUpdated: TStoreStateClass; override;
    class function MakeDeleted: TStoreStateClass; override;
  end;

  StoredUpdated = class(StoredClean)
  public
  end;

  StoredDeleted = class(StoredUpdated)
  public
    class function MakeUpdated: TStoreStateClass; override;
    class function MakeSaved: TStoreStateClass; override;
  end;

implementation

{ TStorageState }

class function TStoreState.IsDeleted: Boolean;
begin
  Result := Self = StoredDeleted;
end;

class function TStoreState.IsUpdated: Boolean;
begin
  Result := Self = StoredUpdated;
end;

class function TStoreState.IsNew: Boolean;
begin
  Result := Self = StoredNew;
end;

class function TStoreState.MakeDeleted: TStoreStateClass;
begin
  Result := Self;
end;

class function TStoreState.MakeUpdated: TStoreStateClass;
begin
  Result := Self;
end;

class function TStoreState.MakeSaved: TStoreStateClass;
begin
  Result := Self;
end;

class function TStoreState.MakeStored: TStoreStateClass;
begin
  Result := Self;
end;

class function TStoreState.MakeStoredClean: TStoreStateClass;
begin
  Result := StoredClean;
end;

{ Transient }

class function Transient.MakeStored: TStoreStateClass;
begin
  Result := StoredNew;
end;

{ StoredClean }

class function StoredClean.MakeDeleted: TStoreStateClass;
begin
  Result := StoredDeleted;
end;

class function StoredClean.MakeUpdated: TStoreStateClass;
begin
  Result := StoredUpdated;
end;

{ StoredDeleted }

class function StoredDeleted.MakeUpdated: TStoreStateClass;
begin
  Result := StoredDeleted;
end;

class function StoredDeleted.MakeSaved: TStoreStateClass;
begin
  Result := Transient;
end;

{ StoredNew }

class function StoredNew.MakeDeleted: TStoreStateClass;
begin
  Result := Transient;
end;

{ Stored }

class function Stored.MakeSaved: TStoreStateClass;
begin
  Result := StoredClean;
end;

end.
