## Guidelines for configuring your application
### Use meaningful names for keys

> As a good developer
>
> you want very specific names in your configuration keys,
>
> so you can avoid potential collision of keys.

#### Bad

```javascript
{
    "Port":"8080"
}
```

#### Good

```javascript
{
    "HttpPort":"8080"
}
```

### Use namespaces

> As a good developer
>
> you want use separation of concerns in your configuration file
>
> so your configuration file can be managed in an easy
> way when your application change.

#### Bad

```javascript
{
    "Port":"8080",
    "StockServicePort":"8040"
}
```

#### Good

```javascript
{
    "WebServer": {
        "HttpPort":"8080"
    }
    "StockService": {
        "HttpPort":"8080"
    }
}
```

### Use IoC

> As a good developer
>
> you want use good coding practices
>
> so your code be easy to extend, test and mantain

#### Bad


```delphi

procedure TSomeObject.SomeMethod;
begin
  // setup service
    FMyConfigurableService.HttpPort := Configuration['HttpPort']
  // ... more setup goes here ...
end

```

#### Good

```delphi

procedure TMyConfigurableService.Create(Config: IConfiguration);
begin
  inherited;
    ...
  Setup(Config)
end

procedure TMyConfigurableService.Setup(Config: IConfiguration);
begin
  // I know how configure my self: just tell me the
  // config you want!!
    ...
    HttpPort := Config['MyConfigurable.HttpPort']

  // Note that this way I can look for my own config keys, so they are
  // mentioneds in a fewer points.
end

```
