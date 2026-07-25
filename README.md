# DMV Health-Tech Accessibility Hackathon

> The product name is intentionally undecided. Please do not introduce a public-facing name without team agreement.

We are building a standalone, conversational application that helps people find restaurants and other places that fit their individual accessibility needs.

Traditional maps answer what is nearby. Accessibility directories list features that may exist. This project is designed to answer a more personal question:

**Will this place work for me?**

## How it works

The application will combine:

1. A user's saved accessibility profile
2. Requirements expressed in the current conversation
3. Accessibility information declared by a business
4. Accessibility evidence observed in customer reviews
5. The recency, consistency, specificity, and confidence of that evidence

A user might ask:

> Find me a quiet Italian restaurant near the National Mall that works with my power wheelchair.

Results will explain the match instead of presenting an unexplained universal score. Each place can include:

- A personalized match score
- Reasons it may work for the current user
- Confirmed accessibility strengths
- Potential accessibility concerns
- Evidence confidence, volume, and recency
- Practical details such as cuisine, price, distance, and hours
- Links for directions, reservations, the business website, and calling

## Product principles

- **Accessibility is personal.** The same place can be a strong match for one person and a poor match for another.
- **Attributes stay separate.** Step-free access, restroom maneuverability, pathway width, noise, lighting, and staff accommodation must not collapse into one universal accessibility label.
- **Unknown is not inaccessible.** Missing evidence must remain unknown and must not be treated as a negative claim.
- **Declared and observed evidence are distinct.** Business claims and customer experiences should be visible and comparable.
- **Explanations matter.** Users should understand why a place received its match result and where uncertainty remains.
- **Accessibility is foundational.** The product itself must be usable with assistive technologies and a wide range of input, vision, hearing, mobility, and sensory needs.

## Example accessibility needs

- Step-free entrance
- Accessible restroom
- Power or manual wheelchair use
- Minimum doorway or pathway width
- Accessible parking
- Maximum comfortable walking distance
- Low-vision accommodations
- Digital or large-text menus
- Quiet-environment preference
- Sensory sensitivity
- Service-animal compatibility
- Staff assistance or communication needs

## Evidence model

Evidence is evaluated per accessibility attribute.

| Attribute | Example assessment |
| --- | --- |
| Step-free entrance | Strongly confirmed |
| Restroom maneuverability | Uncertain |
| Interior pathway width | Likely accessible |
| Noise level | Likely unsuitable |
| Staff accommodation | Strongly positive |
| Large-text menu | No reliable evidence |

Declared information might say that a wheelchair-accessible entrance exists. Observed evidence can add essential context—for example, that the entrance is around the back, a restroom is too narrow for a power wheelchair, or the space becomes very loud after 7 p.m.

## Repository status

This initial commit contains project documentation only. Application and backend scaffolding will be added in later commits.

The planned implementation stack is:

- Flutter for the client application
- Supabase for backend services and data storage

## Team guidance

Contributors and coding agents should read [AGENTS.md](AGENTS.md) before making changes. Claude-specific guidance is available in [CLAUDE.md](CLAUDE.md).

