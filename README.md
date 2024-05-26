## Resources

Method #1: Extract To Separate Struct: Use when you want something, custom and reusable.
Method #2: Extract To Local Computed Property: Use when you want something private and internal.
Method #3: Extract To A Function: Also works for something private and internal, but personally I would prefer a computed property for that use case.
Method #4: Extract To an @ViewBuilder Function: Great for when you want to enable another View to pass you a View.
Method #5: Extract To an @ViewBuilder Computed Property: Great for when you need something internal and private, that also has some internal logic, especially if you need to erase Type.
Method #6: Extract To static func or var: Great for when you want mock example Views.
Method #7: Extract To A Style: Great for when you only want to extract custom styling but not custom logic.
