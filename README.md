# Insert filter plugin for Embulk

Embulk filter plugin that inserts column(s) at any position (e.g., the top/bottom of the columns, before/after the specified column name)

## Overview

* **Plugin type**: filter

## Configuration

### Column(s)

Either "column" or "columns" is required for specifying inserted column(s).

- **column**: associative array that contains only one key-value pair (key means a column name, value means a constant value in the column)
- **columns**: List of the associative arrays

The "column" associate array can contain following optional configuration.

- **as**: type of the constant vaule in the column, i.e. boolean, long, double, string or timestamp (string, default: string)

### Position

Any of the following configurations is required for specifying a position where new columns are inserted.

- **at**: "top", "head", "bottom", "tail" or index number where the new column(s) is/are inserted (string)
- **before**: column name that comes before the new column(s) (string)
- **after**: column name that comes after the new column(s) (string)

If none of the configurations is specified, the new columns are inserted at the bottom of the existing columns.

## Example

Example 1: Insert "host_name" column at the top of the columns

```yaml
filters:
  - { type: insert, column: { host_name: host01 }, at: top }
```

Example 2: Insert "host_name" column at the bottom of the columns

```yaml
filters:
  - { type: insert, column: { host_name: host01 }, at: bottom }
```

Example 3: Insert "host_name" column after second column

```yaml
filters:
  - { type: insert, column: { host_name: host01 }, at: 2 }
```

Example 4: Insert "service_name" column before "host_name" column

```yaml
filters:
  - { type: insert, column: { service_name: service01 }, before: host_name }
```

Example 5: Insert "service_name" column after "host_name" column

```yaml
filters:
  - { type: insert, column: { service_name: service01 }, after: host_name }
```

Example 6: Insert "user_id" column as integer at the bottom of the columns

```yaml
filters:
  - { type: insert, column: { user_id: 1234567, as: integer } }
```

Example 7: Insert multiple columns in a row at the bottom of the columns

```yaml
filters:
  - type: insert
    columns:
      - host_name: host01
      - service_name: service01
```

Example 8: Combination of the above examples

```yaml
filters:
  - type: insert
    columns:
      - service_name: service01
      - { user_id: 1234567, as: integer }
    after: host_name
```

## Build

```
$ rake
```
