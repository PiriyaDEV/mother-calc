export const getQuery = `query {
  boards (ids: 8762692511){
    items_page (limit: 200) {
      cursor
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
}`;

export const postQuery = (id: string) => `
  mutation {
  change_simple_column_value(
    item_id: "${id}"
    board_id: 8762692511
    column_id: "status"
    value: "1"
  ) {
    id
  }
}
`;
