const EMAIL_ID = "text_mknjyj5c";
const NAME_ID = "text_mknjp7ad";

export const query = (column: string, isEmail: boolean = false) => `
  query {
    items_page_by_column_values(
      board_id: 8762692511
      columns: {
        column_id: "${isEmail ? EMAIL_ID : NAME_ID}"
        column_values: "${isEmail ? column.toLowerCase() : column}"
      }
    ) {
      items {
        id 
        name
        column_values {
          column {
            title
          }
          value
          type
        }
      }
    }
  }
`;
