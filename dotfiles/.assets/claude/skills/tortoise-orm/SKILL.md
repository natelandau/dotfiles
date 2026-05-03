---
name: tortoise-orm
description: Build Python applications using Tortoise ORM v1.x, the async Python ORM inspired by Django. Use when writing or modifying Tortoise Model definitions, queries, relations (ForeignKeyField, ManyToManyField, OneToOneField), transactions, signals, validators, Pydantic integration, or Tortoise initialization. Also use when the user mentions Tortoise ORM, tortoise-orm, async ORM with asyncpg/asyncmy, fields.ForeignKeyField, fields.ManyToManyField, prefetch_related, select_related, Tortoise.init, RegisterTortoise, tortoise.contrib.pydantic, or any Tortoise ORM patterns -- even if they don't explicitly say "Tortoise." Covers the full lifecycle: model definition, CRUD, relations, querying, transactions, signals, migrations, testing, and Pydantic serialization.
---

# Tortoise ORM v1.x

Async Python ORM inspired by Django, supporting **PostgreSQL** (asyncpg/psycopg), **MySQL** (asyncmy/aiomysql), **SQLite**, and **MSSQL**.

## Initialization

```python
from tortoise import Tortoise

await Tortoise.init(
    db_url="sqlite://db.sqlite3",
    modules={"models": ["app.models"]},
)
await Tortoise.generate_schemas()  # DEV ONLY -- use migrations in production
```

Multi-database config uses a dict with `connections` and `apps` keys. See `references/api-reference.md` for the full config structure.

**FastAPI integration (v1.x lifespan pattern):**
```python
from contextlib import asynccontextmanager
from tortoise.contrib.fastapi import RegisterTortoise

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with RegisterTortoise(
        app, db_url="sqlite://db.sqlite3",
        modules={"models": ["app.models"]},
        generate_schemas=True,
    ):
        yield

app = FastAPI(lifespan=lifespan)
```

**Connection access (v1.0+ pattern):**
```python
conn = Tortoise.get_connection("default")
await Tortoise.close_connections()
```

The old `from tortoise import connections` import is **deprecated** in v1.0+. Always use `Tortoise.get_connection()`.

## Defining Models

```python
from tortoise.models import Model
from tortoise import fields

class Tournament(Model):
    id = fields.IntField(primary_key=True)
    name = fields.CharField(max_length=255)
    created = fields.DatetimeField(auto_now_add=True)

    class Meta:
        table = "tournaments"
        ordering = ["name"]
```

If no primary key field is defined, an auto-incrementing `IntField` named `id` is created. Access any PK via the `.pk` alias.

**Meta options:** `table`, `schema`, `abstract`, `unique_together`, `indexes`, `ordering`, `table_description`, `fetch_db_defaults`, `manager`.

**Inheritance** works via abstract base classes or mixins:
```python
class TimestampMixin:
    created_at = fields.DatetimeField(null=True, auto_now_add=True)
    modified_at = fields.DatetimeField(null=True, auto_now=True)

class AbstractBase(Model):
    class Meta:
        abstract = True

class User(TimestampMixin, AbstractBase):
    name = fields.CharField(max_length=100)
```

### Fields

**Common parameters:** `null`, `default` (supports callables), `unique`, `db_index`, `source_field` (custom DB column name), `description`, `validators`, `generated`, `primary_key`.

| Category | Fields |
|----------|--------|
| Numeric | `IntField`, `BigIntField`, `SmallIntField`, `FloatField`, `DecimalField(max_digits, decimal_places)` |
| Text | `CharField(max_length)`, `TextField`, `BinaryField` |
| Temporal | `DateField`, `DatetimeField(auto_now, auto_now_add)`, `TimeField`, `TimeDeltaField` |
| Other | `BooleanField`, `UUIDField`, `JSONField(encoder, decoder)`, `CharEnumField(enum_type)`, `IntEnumField(enum_type)` |

**`auto_now` / `auto_now_add` are Python-only** -- they do NOT create a DB DEFAULT clause. For database-level defaults, use `db_default`:
```python
from tortoise.fields.db_defaults import Now, SqlDefault
fields.DatetimeField(db_default=Now())
fields.IntField(db_default=SqlDefault("0"))
```

### Relations

**ForeignKey:**
```python
class Event(Model):
    tournament: fields.ForeignKeyRelation[Tournament] = fields.ForeignKeyField(
        "models.Tournament", related_name="events", on_delete=fields.OnDelete.CASCADE
    )
```
- DB column is `tournament_id` -- accessible directly for performance (avoids fetching the related object)
- `on_delete` options: `CASCADE`, `RESTRICT`, `SET_NULL` (requires `null=True`), `SET_DEFAULT`, `NO_ACTION`

**ManyToMany:**
```python
participants: fields.ManyToManyRelation["Team"] = fields.ManyToManyField(
    "models.Team", related_name="events", through="event_team"
)
```
Both objects must be saved before calling `.add()`.

**OneToOne:**
```python
address: fields.OneToOneRelation[Address] = fields.OneToOneField(
    "models.Address", on_delete=fields.OnDelete.CASCADE, related_name="event"
)
```

**Reverse relations** -- annotate them for type hints:
```python
class Tournament(Model):
    events: fields.ReverseRelation["Event"]
```

## Querying

QuerySets are **lazy** -- they build queries but don't execute until awaited.

```python
# Create
obj = await Model.create(name="foo")
obj = Model(name="foo"); await obj.save()

# Read
obj = await Model.get(id=1)              # raises DoesNotExist / MultipleObjectsReturned
obj = await Model.get_or_none(id=1)       # returns None if not found
items = await Model.filter(name="foo")    # list
items = await Model.all()

# Update
await Model.filter(id=1).update(name="bar")  # bulk, returns count
obj.name = "bar"; await obj.save()            # instance

# Delete
await Model.filter(id=1).delete()
await obj.delete()

# Upsert
obj, created = await Model.get_or_create(name="x", defaults={"field": "val"})
obj, created = await Model.update_or_create(name="x", defaults={"field": "val"})
```

**QuerySet methods:** `filter`, `exclude`, `all`, `first`, `last`, `count`, `exists`, `values`, `values_list`, `only`, `defer`, `order_by`, `limit`, `offset`, `distinct`, `group_by`, `annotate`, `select_related`, `prefetch_related`, `select_for_update`, `using_db`, `raw`, `explain`.

**Filter operators** (double-underscore): `__gt`, `__gte`, `__lt`, `__lte`, `__in`, `__not_in`, `__not`, `__isnull`, `__contains`, `__icontains`, `__startswith`, `__istartswith`, `__endswith`, `__iendswith`, `__iexact`, `__search`, `__range`, `__year`, `__month`, `__day`, etc.

**Q objects** for complex boolean logic:
```python
from tortoise.expressions import Q
await Event.filter(Q(id__in=[1, 2]) | Q(name="3"))
await Event.filter(Q(name="x") & ~Q(tournament__name="y"))
```

**F expressions** for field references:
```python
from tortoise.expressions import F
await Model.filter(field_a__gt=F("field_b"))
await Model.filter(id=1).update(counter=F("counter") + 1)
```

**Aggregation:**
```python
from tortoise.functions import Count, Sum, Avg, Max, Min
result = await Book.annotate(count=Count("id")).group_by("author_id").values("author_id", "count")
```

**Bulk operations:**
```python
await Model.bulk_create([obj1, obj2], batch_size=100)
await Model.bulk_update([obj1, obj2], fields=["name"], batch_size=100)
```

### Fetching Relations

Three approaches -- choose based on context:

| Method | Scope | When to use |
|--------|-------|-------------|
| `select_related("fk_field")` | QuerySet (JOIN) | FK/O2O, small result sets |
| `prefetch_related("m2m_field")` | QuerySet (separate queries) | M2M, reverse FK, nested |
| `await obj.fetch_related("field")` | Single instance | After you already have the object |

**Custom prefetch filtering:**
```python
from tortoise.query_utils import Prefetch
await Tournament.all().prefetch_related(
    Prefetch("events", queryset=Event.filter(name="First"))
)
```

**Cross-relation filtering:**
```python
await Team.filter(events__tournament__id=tournament.id)
```

## Transactions

```python
from tortoise.transactions import in_transaction, atomic

# Context manager
async with in_transaction() as connection:
    await MyModel.create(name="foo")

# Decorator
@atomic()
async def create_pair(data):
    user = await User.create(**data)
    await Profile.create(user=user)
```

Nested `in_transaction` blocks create **savepoints**. Multi-DB: pass `connection_name` parameter.

## Signals

```python
from tortoise.signals import pre_save, post_save, pre_delete, post_delete

@post_save(MyModel)
async def on_save(sender, instance, created, using_db, update_fields):
    if created:
        print(f"New: {instance.id}")
```

The `created` flag on `post_save` indicates INSERT vs UPDATE. Signal handlers must be imported before they can fire.

## Pydantic Integration

```python
from tortoise.contrib.pydantic import pydantic_model_creator, pydantic_queryset_creator

Tournament_Pydantic = pydantic_model_creator(Tournament)
Tournament_PydanticIn = pydantic_model_creator(Tournament, exclude_readonly=True)

# Serialization (read-only -- no deserialization)
pydantic_obj = await Tournament_Pydantic.from_tortoise_orm(instance)
pydantic_obj = await Tournament_Pydantic.from_queryset_single(Tournament.get(id=1))
```

Call `Tortoise.init_models(["app.models"], "models")` before creating Pydantic models if full ORM init hasn't happened yet. Computed fields in `PydanticMeta` must have explicit return type hints.

## Testing (v1.x -- pytest only)

The old unittest-based `TestCase`/`IsolatedTestCase` classes are **removed** in v1.0+.

```python
import pytest_asyncio
from tortoise.contrib.test import tortoise_test_context

@pytest_asyncio.fixture
async def db():
    async with tortoise_test_context(["myapp.models"]) as ctx:
        yield ctx

@pytest.mark.asyncio
async def test_create(db):
    user = await User.create(name="Test")
    assert user.name == "Test"
```

## Migrations (v1.1.7 built-in)

Aerich is legacy. Tortoise v1.1.7 has a built-in migration system:

```bash
tortoise init                    # create migration packages
tortoise makemigrations          # detect changes
tortoise migrate                 # apply
tortoise downgrade models        # reverse
tortoise history                 # list applied
```

Data migrations use `RunPython` (with `apps.get_model()`) or `RunSQL`.

---

## Critical Rules

These are the most common mistakes. Violating them causes bugs that are hard to trace.

### 1. Always await QuerySets

QuerySets are lazy. `Model.filter(name="x")` returns a QuerySet object, not results. You must `await` it.

```python
# WRONG -- silently returns a QuerySet object, not a list
users = Model.filter(active=True)

# CORRECT
users = await Model.filter(active=True)
```

### 2. Always fetch relations before accessing them

Accessing an unfetched relation raises `NoValuesFetched`. There are no lazy-loading shortcuts.

```python
# WRONG -- raises NoValuesFetched
event = await Event.get(id=1)
print(event.tournament.name)

# CORRECT
event = await Event.get(id=1)
await event.fetch_related("tournament")
print(event.tournament.name)

# ALSO CORRECT -- via QuerySet
event = await Event.all().select_related("tournament").get(id=1)
```

### 3. Never use `generate_schemas()` in production

It is for development only. Use the migration system for production deployments.

### 4. Never run concurrent transactions inside `asyncio.gather()`

Transactions are stateful and expect sequential execution. Nesting transaction blocks inside `gather()` or concurrent tasks causes data corruption.

### 5. Use `Tortoise.get_connection()`, not `from tortoise import connections`

The `connections` import is deprecated in v1.0+.

### 6. Save both objects before M2M `.add()`

You cannot add to a ManyToMany relation if either object has not been persisted yet.

### 7. Understand `auto_now` vs `db_default`

`auto_now`/`auto_now_add` are Python-side only. They do not create DB DEFAULT clauses. If you need the database to set defaults (for raw SQL inserts, migrations, etc.), use `db_default=Now()`.

### 8. Call `init_models()` before Pydantic model creation

If you create Pydantic models before full ORM init, relations will not resolve. Call `Tortoise.init_models()` first.

---

For the complete field reference, DB URL formats, engine names, exception hierarchy, validator reference, and advanced patterns, see `references/api-reference.md`.
