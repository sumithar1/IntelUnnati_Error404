module ATP_TB;

  // Inputs
  reg clk;
  reg reset;
  reg card_present;
  reg valid_pin;
  reg [1:0] card_type;
  reg cheque_dd_present;
  reg micr_valid;
  reg [7:0] micr_data;
  reg cash_present;
  reg digital_payment_present;
  reg [7:0] amount_paid;
  reg [7:0] username;
  reg [7:0] password;

  // Outputs
  wire authorized;
  wire use_dd;
  wire use_cash;
  wire use_digital_payment;
  wire adjust_current_supply;

  // Instantiate the pay module
  pay dut (
    .clk(clk),
    .reset(reset),
    .card_present(card_present),
    .valid_pin(valid_pin),
    .card_type(card_type),
    .cheque_dd_present(cheque_dd_present),
    .micr_valid(micr_valid),
    .micr_data(micr_data),
    .cash_present(cash_present),
    .digital_payment_present(digital_payment_present),
    .expected_amount(amount_paid),  // Assuming expected amount is equal to amount paid for simplicity
    .authorized(authorized),
    .use_dd(use_dd),
    .use_cash(use_cash),
    .use_digital_payment(use_digital_payment),
    .adjust_current_supply(adjust_current_supply)
  );

  // Variables for expected amount and current supply status
  reg [7:0] expected_amount;
  reg current_supply_on;

  // Clock generation
  always #5 clk = ~clk;

  // Testcases
  initial begin
    clk = 0;
    reset = 1;
    card_present = 0;
    valid_pin = 0;
    card_type = 2'b00;
    cheque_dd_present = 0;
    micr_valid = 0;
    micr_data = 8'b0;
    cash_present = 0;
    digital_payment_present = 0;
    amount_paid = 0;
    username = 8'h00;
    password = 8'h00;
    expected_amount = 100; // Set the expected amount
    current_supply_on = 1; // Set the current supply status initially ON

    #10 reset = 0; // Deassert reset

    // Test Case 1: Failed login attempt
    username = 8'h12;
    password = 8'h34;
    card_present = 0;
    valid_pin = 0;
    #20;
    card_present = 0;
    #20;
    $display("Test Case 1 - Authorized: %b, Use DD: %b, Use Cash: %b, Use Digital Payment: %b, Adjust Current Supply: %b", authorized, use_dd, use_cash, use_digital_payment, adjust_current_supply);

    // Test Case 2: Successful login, credit card payment
    username = 8'h12;
    password = 8'h56;
    card_present = 1;
    valid_pin = 1;
    card_type = 2'b00;
    amount_paid = expected_amount; // Assuming the expected amount is 100
    #20;
    card_present = 0;
    #20;
    if (adjust_current_supply)
      $display("Test Case 2 - Authorized: %b, Use DD: %b, Use Cash: %b, Use Digital Payment: %b, Adjust Current Supply: Permitted - Electricity is permitted", authorized, use_dd, use_cash, use_digital_payment);
    else
      $display("Test Case 2 - Authorized: %b, Use DD: %b, Use Cash: %b, Use Digital Payment: %b, Adjust Current Supply: Not Permitted - Electricity is disrupted", authorized, use_dd, use_cash, use_digital_payment);

    // Test Case 3: Successful login, MICR payment
    username = 8'h12;
    password = 8'h56;
    cheque_dd_present = 1;
    micr_valid = 1;
    micr_data = 8'bXXXXXXXX;
    amount_paid = expected_amount; // Assuming the expected amount is 100
    #20;
    cheque_dd_present = 0;
    #20;
    $display("Test Case 3 - Authorized: %b, Use DD: %b, Use Cash: %b, Use Digital Payment: %b, Adjust Current Supply: %b", authorized, use_dd, use_cash, use_digital_payment, adjust_current_supply);

    // Test Case 4: Successful login, cash payment
    username = 8'h12;
    password = 8'h56;
    cash_present = 1;
    amount_paid = expected_amount; // Assuming the expected amount is 100
    #20;
    cash_present = 0;
    #20;
    $display("Test Case 4 - Authorized: %b, Use DD: %b, Use Cash: %b, Use Digital Payment: %b, Adjust Current Supply: %b", authorized, use_dd, use_cash, use_digital_payment, adjust_current_supply);

    // Test Case 5: Successful login, digital payment
    username = 8'h12;
    password = 8'h56;
    digital_payment_present = 1;
    amount_paid = expected_amount; // Assuming the expected amount is 100
    #20;
    digital_payment_present = 0;
    #20;
    $display("Test Case 5 - Authorized: %b, Use DD: %b, Use Cash: %b, Use Digital Payment: %b, Adjust Current Supply: %b", authorized, use_dd, use_cash, use_digital_payment, adjust_current_supply);

    $finish;
  end

endmodule