---
description: SOLID principles and TDD enforcement rules for maintainable software design. Reference when analyzing code quality, planning refactoring, or validating architectural decisions.
---

# SOLID Design Rules

## Core Principle

**Design for change containment.**
Predict what will change, and strictly limit how far that change can propagate.

---

## 1. Single Responsibility Principle (SRP)

Every class, module, or function **must have exactly one reason to change**.

**Forbidden:**
- Mixing business rules, data persistence, and formatting in a single class
- "God" services coordinating unrelated concerns
- Methods longer than 20 lines
- Classes with more than 5 dependencies

**Required:**
- Explicit separation of policy, orchestration, and execution
- Small, intention-revealing components

---

## 2. Open/Closed Principle (OCP)

Systems must be **open for extension, closed for modification**.

**Forbidden:**
- `if/switch` chains driven by type or enum growth
- Feature flags embedded in core logic
- Boolean parameters that branch behavior

**Required:**
- Interface-based extensibility
- Strategy and polymorphic dispatch

---

## 3. Liskov Substitution Principle (LSP)

Subtypes must be **fully substitutable** for their base types.

**Forbidden:**
- Empty method implementations in subclasses
- `instanceof` checks in caller code
- Strengthening preconditions in subclasses
- Throwing unexpected exceptions

**Required:**
- Behavioral contracts preserved across all implementations

---

## 4. Interface Segregation Principle (ISP)

Interfaces must be designed **from the client's perspective**.

**Forbidden:**
- Interfaces with more than 5 methods
- Forcing implementations to depend on unused methods

**Required:**
- Role-specific, minimal interfaces
- Separation of commands and queries

---

## 5. Dependency Inversion Principle (DIP)

High-level business logic **must not depend on low-level details**.

**Forbidden:**
- `new` keyword for infrastructure classes in business logic
- Direct database/HTTP client usage in domain services
- Framework annotations in domain entities

**Required:**
- Constructor-based dependency injection
- Interfaces owned by the business layer

---

## 6. TDD Rules

### Tests Before Implementation

1. Failing test scenario defined first
2. Implementation written only to satisfy the test
3. Refactoring follows only after tests pass

### Design Violation Signals

| Signal | Violation |
|--------|-----------|
| Excessive mocking | SRP violation |
| Need to test private methods | Incorrect boundaries |
| DB/network required for unit tests | DIP violation |

---

## 7. Repository Pattern

**Repository = Collection abstraction, NOT persistence mechanism**

**Forbidden:**
- SQL/query language in interface
- Infrastructure terminology in method names

**Required:**
- Domain-centric operations (`find`, `save`, `exists`)
- Must be replaceable with in-memory implementation for testing
