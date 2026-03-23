---
name: beanie-odm
description: Build Python applications using Beanie, the async MongoDB ODM built on Pydantic. Use when writing or modifying Beanie Document models, queries, updates, linked/embedded documents, aggregations, or init_beanie setup. Also use when the user mentions Beanie, MongoDB with Pydantic, Link[], BackLink, fetch_links, beanie.operators, or any Beanie ODM patterns — even if they don't explicitly say "Beanie." Covers the full lifecycle: document definition, CRUD, relations, query operators, update operators, aggregation, and state management.
---

# Beanie ODM

Async Python ODM for MongoDB, built on **Pydantic v2** and **PyMongo's AsyncMongoClient**.

## Initialization

```python
from pymongo import AsyncMongoClient
from beanie import init_beanie

client = AsyncMongoClient("mongodb://localhost:27017")
await init_beanie(
    database=client.my_database,
    document_models=[User, Product, Order],  # All Document/View subclasses
)
```

Parameters:
- `allow_index_dropping=False` — allow dropping indexes not in the model
- `skip_indexes=False` — skip index creation entirely
- `recreate_views=False` — recreate `View` models on startup

When using document inheritance, **every class in the hierarchy** must appear in `document_models`.

## Defining Documents

```python
from beanie import Document, Indexed
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class Address(BaseModel):  # Embedded doc — stored inline, no collection
    street: str
    city: str

class User(Document):
    email: Indexed(str, unique=True)
    username: Indexed(str)
    age: int
    address: Optional[Address] = None
    tags: List[str] = []
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "users"  # Collection name
```

### Settings class options

| Setting | Description |
|---|---|
| `name` | Collection name in MongoDB |
| `indexes` | Additional index definitions (strings, tuples, or `IndexModel`) |
| `use_state_management` | Enable change tracking (`save_changes()`, `rollback()`) |
| `state_management_save_previous` | Also track previous changes |
| `use_revision` | Optimistic concurrency control |
| `use_cache` / `cache_capacity` | Document caching |
| `validate_on_save` | Run Pydantic validation before writes |

### Custom ID

```python
from uuid import UUID, uuid4

class Sample(Document):
    id: UUID = Field(default_factory=uuid4)
```

### Indexes

```python
import pymongo
from pymongo import IndexModel

class Product(Document):
    name: str
    price: Indexed(float)                       # Ascending
    sku: Indexed(str, unique=True)              # Unique
    score: Indexed(float, pymongo.DESCENDING)   # Descending

    class Settings:
        indexes = [
            "name",                                          # Simple
            [("name", pymongo.ASCENDING),
             ("price", pymongo.DESCENDING)],                 # Compound
            IndexModel([("name", pymongo.TEXT)]),             # Text index
        ]
```

### Event hooks

```python
from beanie import before_event, after_event, Insert, Replace, Delete

class Product(Document):
    name: str

    @before_event(Insert)
    def capitalize(self):
        self.name = self.name.capitalize()

    @before_event([Insert, Replace])
    def validate_something(self):
        ...

    @after_event(Delete)
    async def cleanup(self):  # Can be async
        ...
```

Events: `Insert`, `Replace`, `Update`, `Delete`, `Save`, `ValidateOnSave`

## Relations (Linked Documents)

This is Beanie's system for connecting documents across collections. Understand the difference between embedded docs (`BaseModel` — stored inline) and linked docs (`Document` with `Link[]` — separate collections, stored as DBRef).

### Forward Links

```python
from beanie import Document, Link
from typing import List, Optional

class Door(Document):
    height: int = 2
    width: int = 1

class Window(Document):
    x: int = 10
    y: int = 10

class House(Document):
    name: str
    door: Link[Door]                        # Required one-to-one
    side_door: Optional[Link[Door]] = None  # Optional one-to-one
    windows: List[Link[Window]] = []        # One-to-many
    extras: Optional[List[Link[Window]]] = None  # Optional one-to-many
```

Only **top-level fields** are supported for relations.

### BackLink (reverse/virtual)

BackLinks are virtual — nothing is stored in the database. They resolve the relationship from the other direction.

```python
from beanie import BackLink
from pydantic import Field

class Door(Document):
    height: int = 2
    width: int = 1
    # Points back to House.door
    house: BackLink[House] = Field(
        json_schema_extra={"original_field": "door"}
    )

class Person(Document):
    name: str
    # Points back to House.owners (a List[Link[Person]])
    houses: List[BackLink[House]] = Field(
        default=[],
        json_schema_extra={"original_field": "owners"}
    )
```

The `original_field` in `json_schema_extra` names the field on the **other** document that holds the forward `Link`. This Pydantic v2 syntax is required — the older `Field(original_field=...)` is deprecated.

**Critical BackLink behavior:** BackLinks can *only* be populated via `fetch_links=True` on the initial query. You cannot call `fetch_link()` or `fetch_all_links()` on a BackLink after the fact — it will be an empty object.

### Fetching linked documents

```python
# At query time (recommended — single aggregation with $lookup)
house = await House.find_one(House.name == "test", fetch_links=True)
print(house.door.height)  # Door is resolved

houses = await House.find(House.name == "test", fetch_links=True).to_list()

# After retrieval (forward links only, NOT BackLinks)
house = await House.find_one(House.name == "test")
await house.fetch_link(House.door)       # Fetch one link
await house.fetch_all_links()            # Fetch all links
```

### Querying by linked document fields

```python
# By linked doc field (requires fetch_links=True)
houses = await House.find(
    House.door.height == 2,
    fetch_links=True
).to_list()

# By linked doc field in a list
houses = await House.find(
    House.windows.x > 10,
    fetch_links=True
).to_list()

# By linked doc ID (works WITHOUT fetch_links)
from bson import ObjectId
houses = await House.find(
    House.door.id == ObjectId("...")
).to_list()
```

### Nesting depth (self-referencing or deep chains)

```python
# Global depth limit
results = await Node.find(
    fetch_links=True,
    nesting_depth=2
).to_list()

# Per-field depth
results = await Node.find(
    fetch_links=True,
    nesting_depths_per_field={"left": 1, "right": 3}
).to_list()
```

### Write and delete rules for linked docs

```python
from beanie import WriteRules, DeleteRules

# Cascade write — also saves/updates linked docs
await house.save(link_rule=WriteRules.WRITE)
await house.insert(link_rule=WriteRules.WRITE)

# Parent only — don't touch linked docs (default)
await house.save(link_rule=WriteRules.DO_NOTHING)

# Cascade delete — also deletes linked docs
await house.delete(link_rule=DeleteRules.DELETE_LINKS)
```

## Finding Documents

```python
# Find one
product = await Product.find_one(Product.name == "Laptop")

# Get by ID
product = await Product.get("507f1f77bcf86cd799439011")

# Find many
products = await Product.find(Product.price < 500).to_list()

# Find all
all_products = await Product.find_all().to_list()

# First or none
product = await Product.find(Product.price > 1000).first_or_none()

# Sort, skip, limit
results = await Product.find(
    Product.category == "Electronics"
).sort(-Product.price, +Product.name).skip(10).limit(5).to_list()

# Sort alternatives
.sort("-price", "+name")                             # String syntax
.sort([(Product.price, pymongo.DESCENDING)])          # Tuple syntax

# Projection — return a subset of fields as a different model
class ProductShort(BaseModel):
    name: str
    price: float

results = await Product.find().project(ProductShort).to_list()

# Count and existence
count = await Product.find(Product.price > 100).count()
exists = await Product.find(Product.name == "X").exists()

# Async iteration
async for product in Product.find(Product.stock > 0):
    print(product.name)

# Distinct values
categories = await Product.distinct("category")
```

### Native Python operators

These work directly on document fields — no import needed:

`==`, `!=`, `>`, `>=`, `<`, `<=`

Multiple conditions passed to `.find()` are implicitly AND-ed.

```python
products = await Product.find(
    Product.price >= 10,
    Product.price <= 100,
    Product.stock > 0,
).to_list()
```

## Query Operators

`from beanie.operators import <Operator>`

Use these when native Python operators aren't enough (e.g., `$in`, `$or`, `$regex`).

### Comparison

| Operator | MongoDB | Example |
|---|---|---|
| `Eq(field, val)` | `$eq` | `Eq(Product.status, "active")` |
| `GT(field, val)` | `$gt` | `GT(Product.price, 100)` |
| `GTE(field, val)` | `$gte` | `GTE(Product.price, 100)` |
| `LT(field, val)` | `$lt` | `LT(Product.price, 50)` |
| `LTE(field, val)` | `$lte` | `LTE(Product.price, 50)` |
| `NE(field, val)` | `$ne` | `NE(Product.status, "deleted")` |
| `In(field, [vals])` | `$in` | `In(Product.category, ["Books", "Music"])` |
| `NotIn(field, [vals])` | `$nin` | `NotIn(Product.status, ["deleted", "archived"])` |

### Logical

| Operator | MongoDB | Example |
|---|---|---|
| `And(expr, ...)` | `$and` | `And(Product.price < 10, Product.stock > 0)` |
| `Or(expr, ...)` | `$or` | `Or(Product.price < 5, Product.on_sale == True)` |
| `Nor(expr, ...)` | `$nor` | `Nor(Product.deleted == True, Product.stock == 0)` |
| `Not(expr)` | `$not` | `Not(Product.price < 10)` |

```python
from beanie.operators import Or, In

products = await Product.find(
    Or(
        Product.price < 10,
        In(Product.category, ["Sale", "Clearance"]),
    )
).to_list()
```

### Element

| Operator | MongoDB | Example |
|---|---|---|
| `Exists(field, bool)` | `$exists` | `Exists(Product.discount, True)` |
| `Type(field, type)` | `$type` | `Type(Product.price, "decimal")` |

### Evaluation

| Operator | MongoDB | Example |
|---|---|---|
| `RegEx(field, pattern, options=)` | `$regex` | `RegEx(Product.name, "^Laptop", options="i")` |
| `Text(search, ...)` | `$text` | `Text("coffee")` (requires text index) |
| `Where(js_expr)` | `$where` | `Where("this.a > 5")` |

### Array

| Operator | MongoDB | Example |
|---|---|---|
| `ElemMatch(field, query)` | `$elemMatch` | `ElemMatch(Product.reviews, {"score": {"$gte": 4}})` |
| `All(field, [vals])` | `$all` | `All(Product.tags, ["python", "async"])` |
| `Size(field, n)` | `$size` | `Size(Product.tags, 3)` |

## Update Operators

`from beanie.operators import <Operator>`

All take a dict of `{field: value}`.

| Operator | MongoDB | Example |
|---|---|---|
| `Set` | `$set` | `Set({Product.price: 9.99})` |
| `Inc` | `$inc` | `Inc({Product.stock: -1})` |
| `Mul` | `$mul` | `Mul({Product.price: 1.1})` |
| `Max` | `$max` | `Max({Product.price: 50})` |
| `Min` | `$min` | `Min({Product.price: 10})` |
| `Unset` | `$unset` | `Unset({Product.temp_field: ""})` |
| `Push` | `$push` | `Push({Product.tags: "new"})` |
| `Pull` | `$pull` | `Pull(In(Product.tags, ["old", "stale"]))` |
| `AddToSet` | `$addToSet` | `AddToSet({Product.tags: "unique"})` |
| `Pop` | `$pop` | `Pop({Product.tags: -1})` (first) / `1` (last) |
| `CurrentDate` | `$currentDate` | `CurrentDate({Product.updated: True})` |
| `Rename` | `$rename` | `Rename({Product.old: "new"})` |

### Update patterns

```python
from beanie.operators import Set, Inc

# Single document
product = await Product.find_one(Product.name == "Laptop")
await product.update(Set({Product.price: 999}))
await product.update(Set({Product.price: 999}), Inc({Product.stock: 10}))

# Convenience methods (no operator import needed)
await product.set({Product.price: 999})
await product.inc({Product.stock: -1})

# Update via query (update_many)
await Product.find(
    Product.category == "Electronics"
).update_many(Set({Product.on_sale: True}))

# Native MongoDB syntax also works
await Product.find_one(Product.name == "X").update({"$set": {"price": 5}})
```

## Creating Documents

```python
product = Product(name="Laptop", price=999, category="Electronics", stock=50)

await product.insert()       # Insert one
await product.create()       # Alias for insert()
await product.save()         # Insert if no id, replace if has id

await Product.insert_one(product)
await Product.insert_many([product1, product2])
```

### Replace

```python
product.price = 899
await product.replace()  # Replaces entire document
```

### BulkWriter

```python
from beanie import BulkWriter

async with BulkWriter() as bulk:
    await Product.insert_one(p1, bulk_writer=bulk)
    await Product.insert_one(p2, bulk_writer=bulk)
```

## State Management

Requires `use_state_management = True` in Settings.

```python
product = await Product.find_one(Product.name == "Test")
product.price = 200

product.is_changed       # True
product.get_changes()    # {"price": 200}

product.rollback()       # Revert to last saved state
await product.save_changes()  # Sends only changed fields to DB
```

## Aggregation

```python
# Raw pipeline
results = await Order.aggregate([
    {"$match": {"status": "completed"}},
    {"$group": {"_id": "$customer_id", "total": {"$sum": "$amount"}}},
    {"$sort": {"total": -1}},
]).to_list()

# With typed output
class Summary(BaseModel):
    id: str = Field(alias="_id")
    total: float

results = await Order.find(
    Order.status == "completed"
).aggregate(
    [{"$group": {"_id": "$category", "total": {"$avg": "$price"}}}],
    projection_model=Summary,
).to_list()

# Built-in aggregation shortcuts
total = await Product.find(Product.price > 0).sum(Product.price)
avg   = await Product.find(Product.price > 0).avg(Product.price)
mx    = await Product.find(Product.price > 0).max(Product.price)
mn    = await Product.find(Product.price > 0).min(Product.price)
```

### Views (virtual aggregation-backed collections)

```python
from beanie import View

class CategoryStats(View):
    type: str = Field(alias="_id")
    count: int

    class Settings:
        source = Product
        pipeline = [
            {"$group": {"_id": "$category", "count": {"$sum": 1}}},
        ]
```

Register with `recreate_views=True` in `init_beanie`.

## Common Pitfalls

1. **BackLinks require `fetch_links=True` at query time.** You cannot fetch them after the fact. They'll be empty objects.
2. **`Link` fields are DBRefs until fetched.** Accessing `.name` on an unfetched link raises an error. Always check if fetched or use `fetch_links=True`.
3. **Only top-level fields support relations.** Nested `Link[]` inside embedded `BaseModel` is not supported.
4. **`save()` vs `insert()`** — `save()` does upsert (insert or replace). `insert()` always creates new. Use `save()` when you're not sure if the doc exists.
5. **`save_changes()` requires state management.** Enable `use_state_management = True` in Settings, or you'll get an error.
6. **Multiple conditions in `.find()` are AND-ed.** Use `Or()` explicitly when you need OR logic.
7. **`WriteRules.DO_NOTHING` is the default.** Saving a parent doesn't automatically save its linked docs. Pass `link_rule=WriteRules.WRITE` to cascade.
8. **Linked object typing is brittle.** After fetching links, type checkers (mypy/pyright) still see `Link[Door]` rather than `Door`, so accessing attributes like `house.door.height` produces `attr-defined` errors. Add `# type: ignore[attr-defined]` on those accesses. Do not remove these comments — they are intentional workarounds for Beanie's type stubs.
