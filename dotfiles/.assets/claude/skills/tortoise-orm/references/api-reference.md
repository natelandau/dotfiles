# Tortoise ORM v1.x API Reference

## Table of Contents

1. [Initialization Config](#initialization-config)
2. [DB URL Formats](#db-url-formats)
3. [Engine Names](#engine-names)
4. [Field Reference](#field-reference)
5. [Relational Fields](#relational-fields)
6. [Custom Fields](#custom-fields)
7. [Validators](#validators)
8. [QuerySet API](#queryset-api)
9. [Pydantic Integration](#pydantic-integration)
10. [Signals Reference](#signals-reference)
11. [Exception Hierarchy](#exception-hierarchy)
12. [Migration Commands](#migration-commands)

---

## Initialization Config

### Multi-database configuration

```python
CONFIG = {
    "connections": {
        "default": {
            "engine": "tortoise.backends.asyncpg",
            "credentials": {
                "host": "127.0.0.1",
                "port": 5432,
                "user": "user",
                "password": "pass",
                "database": "mydb",
            },
        },
        "secondary": "sqlite://secondary.sqlite3",
    },
    "apps": {
        "app": {
            "models": ["app.models"],
            "default_connection": "default",
        },
        "other": {
            "models": ["other.models"],
            "default_connection": "secondary",
        },
    },
}
await Tortoise.init(config=CONFIG)
```

### `init_models()` for early Pydantic generation

```python
Tortoise.init_models(["__main__"], "models")
```

Required when generating Pydantic models before full ORM init (e.g., at module level for FastAPI schema generation).

---

## DB URL Formats

| Database | URL Format |
|----------|-----------|
| SQLite | `sqlite:///path/to/db.sqlite3` or `sqlite://:memory:` |
| PostgreSQL | `postgres://user:pass@host:5432/database` (also `asyncpg://`, `psycopg://`) |
| MySQL | `mysql://user:pass@host:3306/database` |
| MSSQL | `mssql://user:pass@host:1433/database?driver=...` |

---

## Engine Names

| Backend | Engine |
|---------|--------|
| SQLite | `tortoise.backends.sqlite` |
| PostgreSQL (asyncpg) | `tortoise.backends.asyncpg` |
| PostgreSQL (psycopg) | `tortoise.backends.psycopg` |
| MySQL (asyncmy) | `tortoise.backends.asyncmy` |
| MySQL (aiomysql) | `tortoise.backends.aiomysql` |
| MSSQL | `tortoise.backends.asyncodbc` |

---

## Field Reference

### Common field parameters

All fields accept: `source_field`, `generated`, `primary_key`, `null`, `default` (supports callables), `db_default` (DB-level via `SqlDefault()`), `unique`, `db_index`, `description`, `validators`.

### DB default expressions

```python
from tortoise.fields.db_defaults import SqlDefault, Now, RandomHex

fields.IntField(db_default=SqlDefault("0"))
fields.DatetimeField(db_default=Now())
fields.CharField(max_length=36, db_default=RandomHex())
```

### Enum fields

```python
import enum

class Status(str, enum.Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"

class MyModel(Model):
    status = fields.CharEnumField(Status, default=Status.ACTIVE)
```

If you add values to an enum later, the DB schema will not update automatically -- you need a migration.

### BinaryField limitations

`BinaryField` cannot be used in filters or updates.

---

## Relational Fields

### ForeignKeyField

```python
fields.ForeignKeyField(
    model_name="app.Model",    # "app_label.ModelName" string reference
    related_name="children",    # reverse accessor name
    on_delete=fields.OnDelete.CASCADE,
    db_constraint=True,         # create FK constraint in DB
    null=False,
)
```

The DB column is named `{field_name}_id`. You can read/write `tournament_id` directly to avoid fetching the related object.

### ManyToManyField

```python
fields.ManyToManyField(
    model_name="app.Model",
    through="custom_through_table",  # optional custom through table name
    forward_key="model_id",          # optional custom FK column name
    backward_key="related_id",       # optional custom FK column name
    related_name="reverse_name",
    on_delete=fields.OnDelete.CASCADE,
    db_constraint=True,
    unique=False,
)
```

### OneToOneField

Same parameters as `ForeignKeyField`. Creates a unique FK constraint.

### OnDelete options

| Option | Behavior |
|--------|----------|
| `CASCADE` | Delete related objects |
| `RESTRICT` | Prevent deletion if related objects exist |
| `SET_NULL` | Set FK to NULL (requires `null=True`) |
| `SET_DEFAULT` | Set FK to default value (requires `default`) |
| `NO_ACTION` | Do nothing (DB handles it) |

### ReverseRelation API

```python
await team.events.all()
await team.events.filter(name="First")
await team.events.create(name="New Event")  # auto-sets FK
await team.events.limit(5).offset(10).order_by("-name")
```

### Batch fetching for lists

```python
await Model.fetch_for_list(instances, "events")
```

---

## Custom Fields

```python
class EnumField(fields.CharField):
    def __init__(self, enum_type, **kwargs):
        super().__init__(128, **kwargs)
        self._enum_type = enum_type

    def to_db_value(self, value, instance):
        return value.value

    def to_python_value(self, value):
        return self._enum_type(value)
```

Override `to_db_value` and `to_python_value` for custom serialization.

---

## Validators

### Built-in validators

| Validator | Purpose |
|-----------|---------|
| `RegexValidator(pattern, flags)` | Match regex pattern |
| `MinLengthValidator(min_length)` | Minimum string length |
| `MaxLengthValidator(max_length)` | Maximum string length |
| `MinValueValidator(min_value)` | Minimum numeric value |
| `MaxValueValidator(max_value)` | Maximum numeric value |
| `CommaSeparatedIntegerListValidator(allow_negative)` | Validate CSV integers |
| `validate_ipv4_address` | IPv4 format |
| `validate_ipv6_address` | IPv6 format |
| `validate_ipv46_address` | IPv4 or IPv6 format |

### Custom validators

```python
from tortoise.validators import Validator
from tortoise.exceptions import ValidationError

class EvenNumberValidator(Validator):
    def __call__(self, value: int):
        if value % 2 != 0:
            raise ValidationError(f"Value '{value}' is not even")

# Or as a simple function:
def validate_positive(value):
    if value < 0:
        raise ValidationError("Must be positive")
```

### Usage

```python
class MyModel(Model):
    name = fields.CharField(max_length=100, validators=[MinLengthValidator(3)])
    score = fields.IntField(validators=[MinValueValidator(0), MaxValueValidator(100)])
```

---

## QuerySet API

### Methods reference

| Method | Returns | Description |
|--------|---------|-------------|
| `filter(**kwargs)` | QuerySet | Filter by conditions |
| `exclude(**kwargs)` | QuerySet | Exclude by conditions |
| `all()` | QuerySet | All records |
| `first()` | Model/None | First result |
| `last()` | Model/None | Last result |
| `earliest(*fields)` | Model | Earliest by fields |
| `latest(*fields)` | Model | Latest by fields |
| `get(**kwargs)` | Model | Single result (raises on 0 or 2+) |
| `get_or_none(**kwargs)` | Model/None | Single result or None |
| `count()` | int | Count results |
| `exists()` | bool | Check if any results exist |
| `values(*args, **kwargs)` | list[dict] | Return dicts |
| `values_list(*fields, flat=False)` | list[tuple]/list | Return tuples |
| `only(*fields)` | QuerySet | Load only specified fields |
| `defer(*fields)` | QuerySet | Defer loading of fields |
| `order_by(*fields)` | QuerySet | Order (prefix `-` for DESC) |
| `limit(n)` | QuerySet | Limit results |
| `offset(n)` | QuerySet | Skip results |
| `distinct()` | QuerySet | Distinct results |
| `group_by(*fields)` | QuerySet | Group (use before values) |
| `annotate(**kwargs)` | QuerySet | Add computed fields |
| `select_related(*fields)` | QuerySet | JOIN eager loading (FK/O2O) |
| `prefetch_related(*args)` | QuerySet | Separate-query eager loading |
| `select_for_update(...)` | QuerySet | Row locking |
| `using_db(connection)` | QuerySet | Route to specific DB |
| `raw(sql)` | QuerySet | Raw SQL query |
| `explain()` | dict | Query execution plan |
| `.sql()` | str | Inspect generated SQL |

### Aggregation functions

Import from `tortoise.functions`: `Count`, `Sum`, `Avg`, `Max`, `Min`, `Coalesce`, `Lower`, `Upper`, `Trim`, `Length`.

### select_for_update parameters

```python
qs.select_for_update(
    nowait=False,       # raise instead of waiting
    skip_locked=False,  # skip locked rows
    of=("self",),       # tables to lock
    no_key=False,       # FOR NO KEY UPDATE (PostgreSQL)
)
```

---

## Pydantic Integration

### pydantic_model_creator parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `name` | auto | Model class name |
| `exclude` | `()` | Fields to exclude |
| `include` | `()` | Fields to include (exclusive with exclude) |
| `computed` | `()` | Computed field method names |
| `optional` | `()` | Fields to make Optional |
| `allow_cycles` | `False` | Allow circular references |
| `sort_alphabetically` | `False` | Sort fields alphabetically |
| `exclude_readonly` | `False` | Exclude read-only fields (for input models) |
| `meta_override` | `None` | Override PydanticMeta |
| `model_config` | `None` | Pydantic model config |
| `validators` | `None` | Additional Pydantic validators |
| `module` | `__name__` | Module name for generated class |

### PydanticMeta class

```python
class Tournament(Model):
    name = fields.CharField(max_length=100)
    secret = fields.CharField(max_length=100)

    def name_length(self) -> int:  # return type hint is REQUIRED
        return len(self.name)

    class PydanticMeta:
        exclude = ("secret",)
        computed = ("name_length",)
        allow_cycles = False
        sort_alphabetically = True
```

Computed fields must have explicit return type hints. Async methods are not supported.

### Serialization methods

```python
# Single instance
pydantic_obj = await Model_Pydantic.from_tortoise_orm(instance)

# Single from query (auto-prefetches relations)
pydantic_obj = await Model_Pydantic.from_queryset_single(Model.get(id=1))

# List from query
pydantic_list = await ModelList_Pydantic.from_queryset(Model.all())

# To dict / JSON
pydantic_obj.model_dump()
pydantic_obj.model_dump_json()
```

Relations are automatically prefetched during `.from_tortoise_orm()` and `.from_queryset_single()`.

---

## Signals Reference

### Available signals

| Signal | Parameters |
|--------|-----------|
| `pre_save` | `sender`, `instance`, `using_db`, `update_fields` |
| `post_save` | `sender`, `instance`, `created`, `using_db`, `update_fields` |
| `pre_delete` | `sender`, `instance`, `using_db` |
| `post_delete` | `sender`, `instance`, `using_db` |

### Programmatic registration

```python
MyModel.register_listener(Signals.post_save, handler_fn)
```

Signal handlers must be imported/registered before signals fire.

---

## Exception Hierarchy

| Exception | When raised |
|-----------|------------|
| `BaseORMException` | Base class |
| `DoesNotExist` | `.get()` found nothing |
| `MultipleObjectsReturned` | `.get()` found multiple |
| `IntegrityError` | Constraint violation |
| `ValidationError` | Field validation failure |
| `ConfigurationError` | Setup issues |
| `DBConnectionError` | Connection failures |
| `OperationalError` | General DB operation error |
| `NoValuesFetched` | Accessing unfetched relation |

---

## Migration Commands

### CLI commands (v1.1.7 built-in)

```bash
tortoise init                                    # create migration packages
tortoise makemigrations                          # detect changes and generate migration
tortoise makemigrations --name add_user_field    # named migration
tortoise makemigrations --empty                  # empty template (for data migrations)
tortoise migrate                                 # apply all pending
tortoise upgrade                                 # alias for migrate
tortoise downgrade models                        # reverse latest
tortoise downgrade models 0001_initial           # reverse to specific migration
tortoise history                                 # list applied migrations
tortoise heads                                   # show latest migration on disk
tortoise sqlmigrate models 0001_initial          # preview SQL without executing
```

### Configuration

```python
TORTOISE_ORM = {
    "connections": {"default": "sqlite://db.sqlite3"},
    "apps": {
        "models": {
            "models": ["myapp.models"],
            "default_connection": "default",
            "migrations": "myapp.migrations",  # migration package path
        }
    },
}
```

### Data migrations

**RunPython** -- async Python code:
```python
async def populate_data(apps):
    Model = apps.get_model("app", "Model")
    await Model.create(name="default")

# In migration:
RunPython(populate_data, reverse_code=reverse_fn)
```

**RunSQL** -- raw SQL:
```python
RunSQL("CREATE INDEX ...", atomic=False)  # atomic=False for CREATE INDEX CONCURRENTLY
```

### Programmatic API

```python
from tortoise.migrations.api import migrate, plan
await migrate()  # apply all pending migrations
```
