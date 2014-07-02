# Using the specs
Some specs have been written to guide you towards the lite :) There are rspec
specs in the `spec` directory and ruby code for you to test with in the `test`
directory.

The specs were written with _you_ in mind ;) Run them in this order they should
generally follow the progression of the project.

## Suggested Order
0.  `rake spec spec/controller_base_spec.rb`
0.  `rake spec spec/session_spec.rb`
0.  `rake spec spec/params_spec.rb`
0.  `rake spec spec/router_spec.rb`
0.  `rake spec spec/integration_spec.rb`

Run `rake` to run all the spec files.

If you're feeling extra fancy you can run [guard](https://github.com/guard/guard)! 
just type `guard`
