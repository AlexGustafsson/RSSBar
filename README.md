## Resources

1. Extract To Separate Struct: Use when you want something, custom and reusable.
2. Extract To Local Computed Property: Use when you want something private and internal.
3. Extract To A Function: Also works for something private and internal, but personally I would prefer a computed property for that use case.
4. Extract To an @ViewBuilder Function: Great for when you want to enable another View to pass you a View.
5. Extract To an @ViewBuilder Computed Property: Great for when you need something internal and private, that also has some internal logic, especially if you need to erase Type.
6. Extract To static func or var: Great for when you want mock example Views.
7. Extract To A Style: Great for when you only want to extract custom styling but not custom logic.

### SwiftData gotchas

- Sometimes, you have to populate relationships before saving them, sometimes
  not. Not doing so can make SwiftData crash.
- Sorting an array of a SwiftData model does not always sort the array - not
  even in the local scope. Always store a temporary array first, sort it, and
  then assign it to the model.
- Sometimes, if you look at SwiftData in the wrong way, it will look back and
  crash. The crashes never come with helpful errors. You'll have to use a
  debugger and try to correlate them (segfaults and what not), or comment out
  code until you find the culprit.
- This one is well documented, but always create a new `ModelContext` for every
  thread. This includes completion handlers.
