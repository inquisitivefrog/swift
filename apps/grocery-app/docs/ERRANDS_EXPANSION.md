# Errands Expansion - Future Consideration

## Concept
A separate module or cover page that allows managing errands (non-shopping tasks) similar to how shopping lists work.

## Key Requirements

### Master List of Errands
- Similar to grocery master list
- Short, focused lists per service provider
- Rapid visual scanning (text or image-based)
- Keep lists concise for quick selection

### Example: Auto Dealership Service
**Service Provider:** Auto Dealership  
**Selectable Choices:**
- Oil change
- Annual inspection
- Tune-up
- Repair accident damage

**Design Principle:** Keep choice lists short (4-6 items max) for rapid reading and selection.

### Other Errand Types
- **Gas Station:** Fill up tank, check tire pressure, car wash
- **Bank:** Deposit check, withdraw cash, transfer funds
- **Post Office:** Buy stamps, send package, pick up mail
- **Dry Cleaner:** Pick up clothes, drop off clothes
- **Bakery:** Pick up cake, order custom cake
- **Pharmacy:** Pick up prescription, consult pharmacist
- **Hardware Store:** Buy specific item, return item, get advice

## Architecture Considerations

### Option 1: Separate App Module
- New tab: "Errands"
- Separate data model (ErrandItem, ErrandProvider)
- Similar UI patterns to shopping list
- Pros: Clear separation, focused functionality
- Cons: Code duplication, separate data stores

### Option 2: Unified with Type Field
- Add "Type" field: Shopping vs Errands
- Same data model, filtered by type
- Single app, unified experience
- Pros: Shared code, unified data
- Cons: More complex filtering logic

### Option 3: Cover Page / Home Screen
- Landing page with two options: "Shopping" or "Errands"
- Each leads to appropriate module
- Can share some infrastructure
- Pros: Clear separation, shared foundation
- Cons: Navigation complexity

## Design Principles
1. **Short Lists:** Keep master lists concise (4-6 items per provider)
2. **Visual Selection:** Support both text and icon-based selection
3. **Rapid Scanning:** Optimize for quick visual parsing
4. **Provider-Based:** Organize by service provider (not just task type)
5. **Consistent UX:** Use similar patterns to shopping list for familiarity

## Implementation Notes
- Consider using the same Core Data stack
- Reuse UI components where possible
- Maintain consistent navigation patterns
- Keep data models separate but similar

## Status
**Current:** Documented for future consideration  
**Priority:** Low - focus on shopping list first  
**Timeline:** TBD based on user feedback and needs

