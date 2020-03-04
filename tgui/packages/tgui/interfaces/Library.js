import { decodeHtmlEntities } from 'common/string';
import { Component, Fragment } from 'inferno';
import { act } from '../byond';
import { Box, Button, Input, Section, Table, Tabs } from '../components';

// It's a class because we need to store state in the form of the current
// hovered item, and current search terms
export class Library extends Component {
  constructor() {
    super();
    this.state = {
      search_text
    };
  }

  setSearchText(search_text) {
    this.setState({
      search_text,
    });
  }

  render() {
    const { state } = this.props;
    const { config, data } = state;
    const { ref } = config;
    const { books, search_only, scanner, scanner_title, scanner_author } = data;
    const { search_text } = this.state;
    return (

      <Tabs vertical>
        <Tabs.Tab label="Inventory">
        //Inventory // Checkout // Borrowed
        </Tabs.Tab>
        <Tabs.Tab label="Archive">
          <Section
            title="Books"
            buttons={(
              <Fragment>
                Search
              <Input
                  value={search_text}
                  onInput={(e, value) => this.setSearchText(value)}
                  ml={1}
                  mr={1} />
              </Fragment>
            )}>
            <Table>
              {books.filter(item => {
                const searchTerm = search_text.toLowerCase();
                const searchableString = String(item.title + item.author + item.category).toLowerCase();
                return searchableString.includes(searchTerm);
              }).map(item => {
                return (
                  <Table.Row
                    key={item.id}
                    className="candystripe">
                    <Table.Cell bold>
                      {decodeHtmlEntities(item.title)}
                    </Table.Cell>
                    <Table.Cell bold>
                      {decodeHtmlEntities(item.author)}
                    </Table.Cell>
                    <Table.Cell bold>
                      {decodeHtmlEntities(item.category)}
                    </Table.Cell>
                    {!search_only && (
                      <Table.Cell collapsing textAlign="right">
                        <Button
                          fluid
                          content="Order"
                          onClick={() => act(ref, "order", { "id": item.id })} />
                      </Table.Cell>
                    )}
                  </Table.Row>
                );
              })}
            </Table>
          </Section>
        </Tabs.Tab>
        <Tabs.Tab label="Upload">
          {upload_v}
        </Tabs.Tab>
        <Tabs.Tab label="Printer">
        //Printer/Other
        </Tabs.Tab>
      </Tabs>
    );
  }
}
