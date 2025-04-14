import { CleanedData, ColumnValue } from "./interface";

export function cleanData(data: any[]): CleanedData[] {
  return data?.map((item) => {
    const cleanedItem: CleanedData = {
      id: item.id,
      userNo: item.name,
      subItems: parseValue(getColumnValue(item.column_values, "Subitems")),
      status: parseValue(getColumnValue(item.column_values, "Status")),
    };

    item.column_values.forEach((column: ColumnValue) => {
      if (!["Subitems", "Status"].includes(column.column.title)) {
        cleanedItem[column.column.title] = parseValue(column.value);
      }
    });

    return cleanedItem;
  });
}

function parseValue(value: string): any {
  if (value === "null") {
    return null;
  }

  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}

function getColumnValue(columnValues: ColumnValue[], title: string): string {
  const column = columnValues.find((col) => col.column.title === title);
  return column ? column.value : "";
}
