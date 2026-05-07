#!/usr/bin/env node

const fs = require("fs");

const input = fs.readFileSync(0, "utf8").trim();
const filterValue = process.env.FILTER || "";

if (!input) {
  process.exit(0);
}

let values = JSON.parse(input);
if (!Array.isArray(values)) {
  values = [];
}

const compare = (leftValue, rightValue) => {
  const parse = (value) => {
    const [core, pre = ""] = String(value).split("-");
    const nums = core.split(".").map((part) => Number(part || 0));
    return { nums, pre };
  };

  const left = parse(leftValue);
  const right = parse(rightValue);
  const max = Math.max(left.nums.length, right.nums.length);

  for (let index = 0; index < max; index += 1) {
    const diff = (left.nums[index] || 0) - (right.nums[index] || 0);
    if (diff !== 0) {
      return diff;
    }
  }

  if (!left.pre && right.pre) {
    return 1;
  }

  if (left.pre && !right.pre) {
    return -1;
  }

  return left.pre.localeCompare(right.pre);
};

if (filterValue && filterValue !== "latest") {
  values = values.filter((value) => value === filterValue || value.startsWith(`${filterValue}.`));
}

values.sort(compare);
for (const value of values) {
  process.stdout.write(`${value}\n`);
}
