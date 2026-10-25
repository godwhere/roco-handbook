return {
  item_000000000001 = {
    id = "item_000000000001", name = "Owned egg fixture", group = "eggs",
    icon_available = false, unknown = { condition = nil, flag = false },
    variants = {
      { acquire = {}, related = {{label="Hatch target", title="Owned creature (form A)"}}, condition=nil },
      { acquire = {"Only during the owned fixture event"}, related = {}, condition={count=3} },
    },
  },
}
