module loginsys (
  input wire clk,
  input wire reset,
  input[7:0] username,
  input[7:0] password,
  output reg login_success
);
  
  reg [7:0] stored_username = 8'h12;     // Example stored username: 12
  reg [7:0] stored_password = 8'h56;     // Example stored password: 34
  reg [1:0] state;
  reg [7:0] entered_username;
  reg [7:0] entered_password;
  
  localparam IDLE = 2'b00;
  localparam USERNAME_ENTERED = 2'b01;
  localparam PASSWORD_ENTERED = 2'b10;
  localparam LOGIN_CHECK = 2'b11;
  
  always @(posedge clk) begin
    if (reset)begin
      state <= IDLE;
    end
    
    else begin
      case (state)
        
        IDLE: begin
          if (username !== 8'b0 && password !== 8'b0) begin
            entered_username <= username;
            entered_password <= password;
            state <= USERNAME_ENTERED;
          end
        end
          
        USERNAME_ENTERED:begin
          if (password !== 8'b0) begin
            entered_password <= password;
            state <= PASSWORD_ENTERED;
          end
        end
          
        PASSWORD_ENTERED:begin
          state <= LOGIN_CHECK;
        end
          
        LOGIN_CHECK:begin
          if (username == stored_username && password == stored_password) begin
            login_success = 1'b0;
            //$display("Login Successful");
          end
          
          else begin
            login_success = 1'b1;
            //$display("Login Unsuccessful");
          end
          state <= IDLE;
        end
       endcase
    end
  end
endmodule

//displaying the details upon successful login
module displaydetails(
  
  input wire clk,
  input wire reset,
  input wire [7:0] username,
  input wire [7:0] password,
  inout wire login_success,
  input wire [7:0] user_details
);
  
  loginsys login_inst(
    .clk(clk),
    .reset(reset),
    .username(username),
    .password(password),
    .login_success(login_success)
  );
  
  always @(posedge clk) begin
    if (login_success) begin
      $display("User details: %d", user_details);
    end
  end
endmodule


module ATP (
  input wire clk,                    // Clock input
  input wire reset,                  // Reset input
  input wire card_present,           // Card present signal
  input wire valid_pin,              // Valid PIN signal
  input wire [1:0] card_type,         // Card type: 2'b00 for credit, 2'b01 for debit
  input wire cheque_dd_present,      // Cheque/DD present signal
  input wire micr_valid,             // MICR data valid signal
  input wire [7:0] micr_data,         // MICR data
  input wire cash_present,            // Cash present signal
  input wire digital_payment_present, // Digital payment present signal
  input wire [15:0] expected_amount,  // Expected payment amount
  output reg authorized,              // Authorization output
  output reg use_dd,                   // Use DD payment method
  output reg use_cash,                 // Use cash payment method
  output reg use_digital_payment,      // Use digital payment method
  output reg adjust_current_supply     // Adjust current supply
);

  reg [3:0] state;                    // Internal state register
  reg [15:0] paid_amount;             // Accumulated paid amount

  // State enumeration
  localparam IDLE_STATE = 4'b0000;
  localparam CARD_PRESENT_STATE = 4'b0001;
  localparam PIN_VALID_STATE = 4'b0010;
  localparam MICR_VALID_STATE = 4'b0011;
  localparam CASH_PRESENT_STATE = 4'b0100;
  localparam DIGITAL_PAYMENT_STATE = 4'b0101;
  localparam AUTHORIZED_STATE = 4'b0110;
  
  loginsys login_inst(
  .clk(clk),
  .reset(reset),
  .username(username),
  .password(password),
  .login_success(login_success)
  );
  
  displaydetails display_inst(
  
    .clk(clk),
    .reset(reset),
    .username(username),
    .password(password),
    .login_success(login_success),
    .user_details(user_details)
  );
  always @(posedge clk) begin
    if (reset) begin
      state <= IDLE_STATE;            // Reset the state to idle
      authorized <= 0;                // Reset authorization output
      use_dd <= 0;                    // Reset DD payment method signal
      use_cash <= 0;                  // Reset cash payment method signal
      use_digital_payment <= 0;       // Reset digital payment method signal
      adjust_current_supply <= 0;     // Reset adjust current supply signal
      paid_amount <= 0;               // Reset paid amount
    end
    else begin
      case (state)
        IDLE_STATE: begin
          if (card_present) begin
            state <= CARD_PRESENT_STATE;  // Move to card present state
          end
          else if (cheque_dd_present) begin
            state <= MICR_VALID_STATE;    // Move to MICR valid state
          end
          else if (cash_present) begin
            state <= CASH_PRESENT_STATE;  // Move to cash present state
          end
          else if (digital_payment_present) begin
            state <= DIGITAL_PAYMENT_STATE;  // Move to digital payment state
          end
        end

        CARD_PRESENT_STATE: begin
          if (valid_pin) begin
            state <= PIN_VALID_STATE;     // Move to PIN valid state
          end
          else begin
            state <= IDLE_STATE;          // Invalid PIN, go back to idle
          end
        end

        PIN_VALID_STATE: begin
          if (card_type == 2'b00) begin
            // Credit card authorization logic
            state <= AUTHORIZED_STATE;    // Move to authorized state
            authorized <= 1;              // Set authorization output to high
            use_dd <= 0;                  // Use cheque for payment
          end
          else if (card_type == 2'b01) begin
            // Debit card authorization logic
            state <= AUTHORIZED_STATE;    // Move to authorized state
            authorized <= 1;              // Set authorization output to high
            use_dd <= 0;                  // Use cheque for payment
          end
          else begin
            state <= IDLE_STATE;          // Invalid card type, go back to idle
          end
        end

        MICR_VALID_STATE: begin
          if (micr_valid && micr_data == 8'bXXXXXXXX) begin
            // MICR authorization logic for valid data
            state <= AUTHORIZED_STATE;    // Move to authorized state
            authorized <= 1;              // Set authorization output to high
            use_dd <= 1;                  // Use DD for payment
          end
          else begin
            state <= IDLE_STATE;          // Invalid MICR data, go back to idle
          end
        end

        CASH_PRESENT_STATE: begin
          // Cash payment logic
          state <= AUTHORIZED_STATE;      // Move to authorized state
          authorized <= 1;                // Set authorization output to high
          use_dd <= 0;                    // Use cheque for payment
          use_cash <= 1;                  // Use cash for payment
        end

        DIGITAL_PAYMENT_STATE: begin
          // Digital payment logic
          state <= AUTHORIZED_STATE;      // Move to authorized state
          authorized <= 1;                // Set authorization output to high
          use_dd <= 0;                    // Use cheque for payment
          use_digital_payment <= 1;       // Use digital payment for payment
        end

        AUTHORIZED_STATE: begin
          if (paid_amount >= expected_amount) begin
            state <= IDLE_STATE;          // Payment complete, go back to idle
            authorized <= 0;              // Reset authorization output
            use_dd <= 0;                  // Reset DD payment method signal
            use_cash <= 0;                // Reset cash payment method signal
            use_digital_payment <= 0;     // Reset digital payment method signal
            adjust_current_supply <= 0;   // DO NOT Adjust current supply
            paid_amount <= paid_amount - expected_amount;
          end
          else if (paid_amount < expected_amount) begin
            // Payment is less than the expected amount, do not supply current
            state <= IDLE_STATE;          // Go back to idle state
            authorized <= 0;              // Reset authorization output
            use_dd <= 0;                  // Reset DD payment method signal
            use_cash <= 0;                // Reset cash payment method signal
            use_digital_payment <= 0;     // Reset digital payment method signal
            adjust_current_supply <= 1;   //  adjust current supply
          end
        end
      endcase

      // Accumulate the paid amount based on the payment method
      if (cash_present || digital_payment_present) begin
        paid_amount <= paid_amount + expected_amount;
      end
    end
  end

endmodule