context("JSON equivalence")

test_that("json_compare", {
    obj <- list(c=1, b=list(list(2, 3), list(d=9, f=5)), a=5)
    expect_false(json_compare(list(1, 2), list(2, 1))$equal)
    expect_false(json_compare(obj,
        list(c=1, b=list(list(3, 2), list(d=9, f=5)), a=5))$equal)
    expect_false(json_compare(obj,
        list(c=1, b=list(list(d=9, f=5), list(2, 3)), a=5))$equal)
})

public({
    test_that("JSON equivalence", {
        obj <- list(c=1, b=list(list(2, 3), list(d=9, f=5)), a=5)
        expect_json_equivalent(4, 4)
        expect_json_equivalent(list(n=5, q=list(r=55, p=9)),
            list(q=list(p=9, r=55), n=5))
        expect_json_equivalent(list(1, 2), list(1, 2))
        expect_json_equivalent(list(b=list(list(2, 3), list(f=5, d=9)), c=1, a=5),
            obj)
    })
})
