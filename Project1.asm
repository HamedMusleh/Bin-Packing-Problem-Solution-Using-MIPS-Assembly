.data
menu: .asciiz "\nWelcome to Bin Packing Problem Solution \nChoose the operation \n1-First Fit(By Enter FF)\n2-Best Fit(By Enter BF)\n3-Exit(By Enter Q/q).\n4-Print File(By Enter P)\n"
Op: .space 5  # Stores user input (3 bytes to accommodate two characters plus null termination)
invalid_input_msg: .asciiz "Error: Invalid number found in file (>= 1.0).\n"
least_bins_label: .asciiz "Minimum number of bins used: "  
first_fit_result_label: .asciiz "First Fit Result:\n"
best_fit_result_label: .asciiz "Best Fit Result:\n"
DASH : .asciiz "----------------------------------------------------------\n"
First_Fit: .asciiz "\nFirst Fit Selected\n"
Best_Fit : .asciiz "\nBest Fit Selected\n"
Exit: .asciiz "\nExiting...\n"
newline:    .asciiz "\n"
Error_input: .asciiz "\nError: Invalid input, please try again.\n"
filename : .space 256  # Space to store the file name
store_file : .space 1024  # Buffer to store file contents
message_to_enter_file : .asciiz "Enter file Path or The name of file or Press Q / q to exit : "
errorMsg: .asciiz "\nError: Could not open file.\n"
msg_lines: .asciiz "Number of lines in the file: "
error_message_file: .asciiz "\nthe file does not exist or Press Q / q to exit \n" 
size: .word 0  # Stores the number of lines in the file
array_num:  .space 1000
array_float: .space 1000
one: .float 1.0
prefix: .asciiz "0." 
bin_label: .asciiz "Bin "
colon_space: .asciiz ": "
space: .asciiz " "
zero : .float 0.0
hundred : .float 10000.0
int_buffer:    .space 12          # Space to save numbers as text
bin_index:     .word 0            # Save the start place of bin index list
float_array:   .float 0.0         # Save float numbers (will change later)
TOTAL_ITEMS:   .word 0            # Save how many items we have
buffer_ptr:    .word 0            # Save where we are in the final buffer
temp_buf:      .space 12          # Small buffer to help format numbers
output_file:   .asciiz "out.txt" # Name of the file to write the answer
final_buffer:  .space 2048        # Big buffer to save all the output before writing
output_buffer: .space 2048
buffer_index: .word 0
epsilon: .float 0.00001
debug_create_bin: .asciiz "No bin fits, creating new bin\n"
# Name : Hamed Musleh ID : 1221036
# Name : Mousa Zahran ID : 1220716
.text
.globl main 

main:
    # Ensure the user provides a valid file path or chooses to exit
request_filename:
    li $v0, 4
    la $a0, message_to_enter_file  # Display message asking for file path or name
    syscall

    # Read the file name from user input
    li $v0, 8
    la $a0, filename
    li $a1, 256  # Max size of input (256 bytes)
    syscall

    # Remove the newline character (\n)
    jal remove_newline

    # Check if the user entered 'q' or 'Q' to exit
    lb $t0, filename        # Load the first character of the input (filename)
    lb $t3, filename + 1    # Load the second character of the input
    li $t1, 'q'             # ASCII value of 'q'
    li $t2, 'Q'             # ASCII value of 'Q'
    li $t4, 0               # Null character (ASCII value 0)

    # Check if the first character is 'q' or 'Q' and the second character is null
    beq $t0, $t1, check_second_char_null   # If first character is 'q', check the second character
    beq $t0, $t2, check_second_char_null   # If first character is 'Q', check the second character

    # If the first character is not 'q' or 'Q', and the second is not null
    b continue_reading

check_second_char_null:
    beqz $t3, exit           # If the second character is null, exit the program
    b continue_reading

continue_reading:

    # Open the file in read mode
    li $v0, 13
    la $a0, filename
    li $a1, 0  # Read mode
    syscall

    # If the file does not exist, show an error message and ask for input again
    bltz $v0, fileError  
    move $s0, $v0  # Store the file descriptor in $s0

    # Read file contents into store_file buffer
    li $v0, 14
    move $a0, $s0   
    la $a1, store_file  
    li $a2, 1024  # Read up to 1024 bytes
    syscall

    # Count the number of lines in the file
    jal count_lines

    # Close the file
    li $v0, 16
    move $a0, $s0
    syscall
    
     # Start processing the file content (convert to floats)
    la $t1, store_file      # Load address of the input buffer
    la $s1, array_num       # Load address of the array to store numbers
    li $s2, 0               # Initialize counter for numbers

convert_to_number:
    lb $t0 , 0($t1)         # Load current character
    move $t5 , $t1          # Save current pointer in t5
    move $t6 , $zero        # Clear temporary register

    beqz $t0 , done_read    # If end of string, jump to done_read
    beq $t0 , 10 , next_line # If newline, skip to next line
    beq $t0 , 46 , decimal_point # If '.', go to read fractional part
 
    
    sub $t0 , $t0 , 48      # Convert ASCII digit to integer
    move $t8 , $t0          # Store digit in t8
    addi $t1 , $t1 , 1      # Move to next character
    j convert_to_number     # Continue reading number
    


decimal_point:
    addi $t1 , $t1 , 1      # Skip '.'
    li $t9, 0               # Initialize fractional accumulator
    li $t7, 1               # Initialize divisor base (10)

read_fraction:
    lb $t0, 0($t1)          # Load current character
    beqz $t0, finalize_number      # If end of string, finalize number
    beq $t0, 10, finalize_number   # If newline, finalize number
    blt $t0, 48, finalize_number   # If not digit, finalize
    bgt $t0, 57, finalize_number

    sub $t0, $t0, 48        # Convert ASCII digit to integer
    mul $t9, $t9, 10        # Multiply fractional part by 10
    add $t9, $t9, $t0       # Add new digit
    mul $t7, $t7, 10        # Multiply divisor by 10
    addi $t1, $t1, 1        # Move to next character
    j read_fraction         # Continue reading fraction

finalize_number:
    # Combine integer and fractional parts as float by dividing by t7
    mul $t8, $t8, $t7
    add $t8, $t8, $t9

    mtc1 $t8, $f0
    cvt.s.w $f0, $f0
    mtc1 $t7, $f2
    cvt.s.w $f2, $f2
    div.s $f0, $f0, $f2
   
   
    # Check if the float is >= 1.0 (invalid)
    l.s $f4, one
    c.le.s $f4, $f0
    bc1t invalid_number_error


    # Store result in array_num
    swc1 $f0, 0($s1)
    addi $s1, $s1, 4
    addi $s2, $s2, 1

    j convert_to_number

next_line:
    addi $t1 ,$t1 , 1
    j convert_to_number
    
done_read:
    # Print out the floats (optional testing step)
    la $t3, array_num
    li $t4, 0

print_loop:
    bge $t4, $s2, print_end
    lwc1 $f12, 0($t3)
    li $v0, 2
    syscall

    # Print newline
    li $v0, 4
    la $a0, newline
    syscall

    addi $t3, $t3, 4
    addi $t4, $t4, 1
    j print_loop
    
invalid_number_error:
    li $v0, 4
    la $a0, invalid_input_msg
    syscall
    j request_filename

print_end:
    # Go to the menu
    j menu_loop


fileError:
    # Print an error message if the file doesn't exist
    li $v0, 4
    la $a0, error_message_file
    syscall
    j request_filename  # Retry file input


# Menu loop to display options to the user
menu_loop:
    # Display menu options
    li $v0, 4
    la $a0, menu
    syscall

    # Read user input (FF, BF, P, or Q)
    la $a0, Op
    li $a1, 3  # Limit input size to 3 bytes
    li $v0, 8
    syscall

    # Process user input
    jal process_input
    b menu_loop


# Process the user input to determine what action to take
process_input:
    # Load first and second characters from user input
    lb $t3, Op
    lb $t4, Op + 1

    # Convert 'q' to 'Q' if needed
    li $t6, 'q'
    li $t7, 'Q'
    beq $t3, $t6, check_null_to_exit
    beq $t3, $t7, check_null_to_exit
    b check_first_fit
    
check_null_to_exit: 
    beq $t4, 10 ,exit        
    b error_invalid_input
    
check_first_fit:
    li $t0, 'F'

    # Reject lowercase 'ff' and show error
    li $t2, 'f'
    beq $t3, $t2, check_second_ff_lower # check first char if "f"
    beq $t3, $t0, check_second_ff  # Check if input is "FF"
    b check_best_fit

check_second_ff_lower:
    beq $t4, $t2, First_fit  # If "ff", show error
    beq $t4 , $t0 , First_fit
    b error_invalid_input
    #b check_best_fit

check_second_ff:
    beq $t4, $t0, First_fit
    b check_best_fit

check_best_fit:
    li $t0, 'B'
    li $t1, 'F'
    
    # Reject lowercase 'bf' and show error
    li $t2, 'b'
    li $t6 , 'f'
    beq $t3, $t2, check_second_bf_lower
    beq $t3, $t0, check_second_bf  # Check if input is "BF"
    b check_print_file
    
check_second_bf_lower:
    beq $t4, $t1, Best_fit  # If "bF", show error
    beq $t4 , $t6 , Best_fit
    b error_invalid_input
check_second_bf:
    beq $t4, $t1, Best_fit
    b check_print_file

check_print_file:
    li $t0, 'P'
    beq $t3, $t0, check_null_to_print
    b error_invalid_input

check_null_to_print: 
    beq $t4 , 10 ,print_file
    b  error_invalid_input
error_invalid_input:
    # Print error message for invalid input
    li $v0, 4
    la $a0, Error_input
    syscall
    jr $ra

First_fit:
    li $v0, 4
    la $a0, First_Fit
    syscall

    la $t0, size
    lb $t1, 0($t0)         # Load number of items (n_items)
    move $s4, $t1          # Save n_items in $s4 (saved register)

    # Allocate memory for bins array (remaining capacities)
    li $t0, 4
    mul $a0, $s4, $t0      # n_items * 4 bytes
    li $v0, 9
    syscall
    move $s1, $v0          # $s1: bins array

    # Allocate memory for bin_assignments array (stores bin index per item)
    mul $a0, $s4, 4        # n_items * 4 bytes
    li $v0, 9
    syscall
    move $s3, $v0          # $s3: bin_assignments array

    li $s2, 0              # $s2: bin_count (initialized to 0)
    la $t3, array_num      # $t3: pointer to items array
    li $t4, 0              # $t4: item index (i = 0)

# read items from array , and addresses of items .
loop_items:
    beq $t4, $s4, done_pack # t4 == s4 , s4 = num of item , t4 = index

    sll $t5, $t4, 2        # Calculate item offset
    add $t6, $t3, $t5
    lwc1 $f0, 0($t6)       # $f0 = current item size

    li $t7, 0              # $t7: bin index (j = 0)

find_bin:
    beq $t7, $s2, create_bin

    sll $t8, $t7, 2        # Calculate bin offset
    add $t9, $s1, $t8
    lwc1 $f1, 0($t9)       # $f1 = bin's remaining capacity

    l.s $f3, epsilon       # Load epsilon
    add.s $f4, $f1, $f3    # f4 = bin + epsilon

    c.le.s $f0, $f4        # if item <= bin + epsilon
    bc1t place_item_in_bin

    addi $t7, $t7, 1
    j find_bin

place_item_in_bin:
    sll $t8, $t7, 2
    add $t9, $s1, $t8
    lwc1 $f1, 0($t9)
    sub.s $f1, $f1, $f0    # Deduct item size from bin
    swc1 $f1, 0($t9)
    j update_item_done

create_bin:
    l.s $f2, one           # Load 1.0 into $f2
    sub.s $f1, $f2, $f0    # New bin's remaining capacity
    sll $t8, $s2, 2
    add $t9, $s1, $t8
    swc1 $f1, 0($t9)       # Store new bin's capacity
    move $t7, $s2          # Current bin index is s2
    addi $s2, $s2, 1       # Increment bin_count

update_item_done:
    # Record bin assignment for current item
    sll $t8, $t4, 2        # Item index * 4
    add $t9, $s3, $t8      # Address in bin_assignments
    sw $t7, 0($t9)         # Store bin index

    addi $t4, $t4, 1       # Next item
    j loop_items
	
#--------------------------------------------------
# done_pack: Aggregate all output in final_buffer, then print once
#--------------------------------------------------
done_pack:
    li $t0, 0                   # index
    la $t1, array_num
    la $t2, array_float

copy_loop_array:
    beq $t0, 250, end_copy_array

    sll $t3, $t0, 2             # offset = index * 4

    add $t4, $t1, $t3
    add $t5, $t2, $t3

    lwc1 $f0, 0($t4)
    swc1 $f0, 0($t5)

    addi $t0, $t0, 1
    j copy_loop_array

end_copy_array:
    
    #––– Init buffer_ptr to start of final_buffer
    la   $t1, final_buffer
    sw   $t1, buffer_ptr
    ## FF
#––– Append "First Fit Result:\n" to final_buffer
    la   $t0, first_fit_result_label
    lw   $t1, buffer_ptr
    jal  copy_loop
    j ff
print_on_OutputFile: 

#––– Append "Best Fit Result:\n"
    la   $t0, best_fit_result_label
    lw   $t1, buffer_ptr
    jal  copy_loop
ff :
    #––– Append “Least number of bins used: ” + $s2 + newline
    la   $t0, least_bins_label   # Load the text address into $t0
    lw   $t1, buffer_ptr         # Load where we are in the buffer
    jal  copy_loop               # Call the loop to copy the text


    # Print the number (least bins)
    move $a0, $s2                # Move the number from $s2 to $a0
    li   $v0, 1                  # Set syscall code for printing integer
    syscall                      # Run syscall to print the number


    # Print new line
    li   $v0, 4                  # Set syscall code to print string
    la   $a0, newline            # Load the address of the new line text
    syscall                      # Run syscall to print the new line


    move $a1, $s2          # Put the number in $a1
    la   $a0, temp_buf     # Load address of temp_buf into $a0
    jal  int_to_string     # Change the number in $s2 to text and save in temp_buf

    move $t0, $v0          # $v0 has the pointer to the text in temp_buf
    lw   $t1, buffer_ptr   # Load where we are in the final buffer
    jal  copy_loop         # Copy the number text to the final buffer

    la   $t0, newline
    lw   $t1, buffer_ptr
    jal  copy_loop

    #––– Now list each bin’s items
    li   $t5, 0            # j = 0
    
    
loop_bins:
    beq  $t5, $s2, end_bins

    # Append "Bin "
    la   $t0, bin_label
    lw   $t1, buffer_ptr
    jal  copy_loop

    # Append bin number (j+1)
    addi $a1, $t5, 1
    la   $a0, temp_buf
    jal  int_to_string

    move $t0, $v0
    lw   $t1, buffer_ptr
    jal  copy_loop

    # Append ": "
    la   $t0, colon_space
    lw   $t1, buffer_ptr
    jal  copy_loop

    #––– loop items in bin j
    li   $t6, 0            # i = 0

loop_items_1:
    la   $t3, array_float
    beq  $t6, $s4, end_items    # If current index == total items, go to end

    sll  $t7, $t6, 2            # Multiply index by 4 (to get byte offset)
    add  $t8, $s3, $t7          # Address = base of bin array + offset
    lw   $t9, 0($t8)            # Load bin index of current item into $t9
    bne  $t9, $t5, skip_item    # If item not in this bin, skip it

    # Load float value of the item into $f12
    sll  $t7, $t6, 2            # Get offset of the item in array_num
    add  $t8, $t3, $t7          # Address = base of array_num + offset

    lwc1 $f12, 0($t8)           # Load float number from array_num into $f12
    # Append "prefix 0. "
    la   $t0, prefix            # Load the address of prefix
    lw   $t1, buffer_ptr        # Load current buffer pointer
    jal  copy_loop              # Copy prefix text to buffer

    # Multiply by 10000.0
    l.s  $f14, hundred          # Load 10000.0 into $f14
    mul.s $f12, $f12, $f14      # Multiply $f12 by 100.0
    cvt.w.s $f12, $f12          # Convert float $f12 to integer
    mfc1 $a0, $f12              # Move result from $f12 to $a0 (for printing or storing)
    move $a1 , $a0
    la $a0 , temp_buf
    jal  int_to_string
    move $t0, $v0
    lw   $t1, buffer_ptr
    jal  copy_loop
    

    #move $t0, $v0
    #lw   $t1, buffer_ptr
    #jal  copy_loop
    
   
    # append space
    la   $t0, space
    lw   $t1, buffer_ptr
    jal  copy_loop
    

skip_item:
    addi $t6, $t6, 1
    j    loop_items_1

end_items:
    # append newline after each bin
    la   $t0, newline
    lw   $t1, buffer_ptr
    jal  copy_loop

    addi $t5, $t5, 1
    j    loop_bins

end_bins:
    la   $t0, DASH
    lw   $t1, buffer_ptr
    jal  copy_loop
    #––– Finally, print the entire buffer in one syscall
    la   $a0, final_buffer
    li   $v0, 4
    syscall
    # --------------------------------------
    # Calculate the length of final_buffer
    la   $a0, final_buffer       # Load the address of final_buffer into $a0
    jal  count_buffer_length     # Call the function to get how long the buffer is

    # Print the length (for checking/debugging)
    move $a0, $t0                # Move the result (length) to $a0
    li   $v0, 1                  # Set syscall code to print integer
    syscall                      # Print the length on the screen

    move $a2, $t0                # Save the length in $a2 (used for writing to file)
    # --------------------------------------

    # Open file for writing
    li $v0, 13                 # syscall 13: open file
    la $a0, output_file        # Filename
    li $a1, 9                  # Flags: O_WRONLY | O_CREAT | O_TRUNC = 9
    li $a2, 0x1FF              # Permissions: 0777
    syscall
    move $s7, $v0              # Save file descriptor

    # Write to file
    li $v0, 15                 # syscall 15: write to file
    move $a0, $s7              # File descriptor
    la $a1, final_buffer       # Buffer address
    # $a2 already contains the buffer length
    syscall

    # Close file
    li $v0, 16                 # syscall 16: close file
    move $a0, $s7              # File descriptor
    syscall

    j menu_loop                # Return to main loop

# =========================================
# Function: count_buffer_length
# Description: Counts number of bytes in a buffer until null terminator
# Input: $a0 - address of the buffer
# Output: $t0 - length of the buffer (excluding null byte)
# =========================================
count_buffer_length:
    li $t0, 0              # Initialize counter to 0

count_loop_final_buffer:
    lb $t1, 0($a0)         # Load byte from buffer
    beqz $t1, done_count_final_buffer   # If byte is zero (null terminator), stop
    addi $t0, $t0, 1       # Increment counter
    addi $a0, $a0, 1       # Move to next byte
    j count_loop_final_buffer

done_count_final_buffer:
    jr $ra                 # Return from function



#--------------------------------------------------
# copy_loop: Copy null?terminated string from $t0 ? [$t1]
# updates buffer_ptr to new end
# returns via jr $ra
# uses: $t2
#--------------------------------------------------
copy_loop:
    lb   $t2, 0($t0)
    sb   $t2, 0($t1)
    beqz $t2, end_copy
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    sw   $t1, buffer_ptr
    j    copy_loop
end_copy:
    jr   $ra
    
#--------------------------------------------------
# int_to_string: convert integer in $a1 ? ASCII in $a0 (temp_buf)
# returns: $v0 = pointer to start of ASCII string
# uses: $t0–$t3, $ra
#--------------------------------------------------
int_to_string:
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $t0,   8($sp)
    sw   $t1,   4($sp)
    sw   $t2,   0($sp)

    move $t0, $a1         # Copy the value from $a1 to $t0
    li   $t1, 10
    addi $t2, $a0, 11     # ????? temp_buf
    sb   $zero, 0($t2)    # null terminator

conv_loop:
    beqz $t0, conv_done
    divu $t0, $t1
    mfhi $t3
    mflo $t0
    addi $t3, $t3, 48
    addi $t2, $t2, -1
    sb   $t3, 0($t2)
    j    conv_loop

conv_done:
    move $v0, $t2         # Move the pointer (to the result) into $v0
    lw   $ra, 12($sp)
    lw   $t0,   8($sp)
    lw   $t1,   4($sp)
    lw   $t2,   0($sp)
    addi $sp, $sp, 16
    jr   $ra

    	
    
append_null:
    add $t0, $a0, $a1   # t0 = base + index
    sb  $zero, 0($t0)   # store byte 0 (null terminator)
    jr $ra              # return
    
# "Best Fit" selection message

Best_fit:
###########################################################################################################################
    li $v0, 4
    la $a0, Best_Fit
    syscall

    la $t0, size
    lb $t1, 0($t0)
    move $s4, $t1          # $s4 = n_items

    # Allocate memory for bins array
    li $t0, 4
    mul $a0, $s4, $t0
    li $v0, 9
    syscall
    move $s1, $v0          # $s1 = bins array

    # Allocate memory for bin_assignments array
    mul $a0, $s4, 4
    li $v0, 9
    syscall
    move $s3, $v0          # $s3 = bin_assignments array

    li $s2, 0              # bin_count
    la $t3, array_num      # items array
    li $t4, 0              # item index (i = 0)

loop_items_bf:
    beq $t4, $s4, done_pack_bf

    sll $t5, $t4, 2
    add $t6, $t3, $t5
    lwc1 $f0, 0($t6)       # $f0 = current item size

    li $t7, 0              # j = 0 (bin index)
    li $t9, -1             # best_bin = -1 (none found)
    l.s $f3, one           # f3 = 1.0 (to hold min remaining)

find_best_bin:
    beq $t7, $s2, check_best_bin

    sll $t8, $t7, 2
    add $t1, $s1, $t8
    lwc1 $f1, 0($t1)       # $f1 = bin's remaining capacity

    # Compare using tolerance: if (item <= bin + epsilon)
    l.s $f5, epsilon
    add.s $f6, $f1, $f5
    c.le.s $f0, $f6
    bc1f skip_bin

    sub.s $f4, $f1, $f0    # remaining after placing item

    c.lt.s $f4, $f3
    bc1f skip_bin

    mov.s $f3, $f4         # f3 = new min remaining
    move $t9, $t7          # best_bin = j

skip_bin:
    addi $t7, $t7, 1
    j find_best_bin

check_best_bin:
    bne $t9, -1, place_item_in_best_bin

# no bin found, create new bin
create_bin_bf:
    l.s $f2, one
    sub.s $f1, $f2, $f0
    sll $t8, $s2, 2
    add $t9, $s1, $t8
    swc1 $f1, 0($t9)
    move $t9, $s2
    addi $s2, $s2, 1

    j update_item_done_bf

place_item_in_best_bin:
    sll $t8, $t9, 2
    add $t1, $s1, $t8
    lwc1 $f1, 0($t1)
    sub.s $f1, $f1, $f0
    swc1 $f1, 0($t1)



update_item_done_bf:
    sll $t8, $t4, 2
    add $t1, $s3, $t8
    sw $t9, 0($t1)

    addi $t4, $t4, 1
    j loop_items_bf

done_pack_bf:
    li $t0, 0                   # index
    la $t1, array_num
    la $t2, array_float

copy_loop_array_bf:
    beq $t0, 250, end_copy_array_bf

    sll $t3, $t0, 2             # offset = index * 4

    add $t4, $t1, $t3
    add $t5, $t2, $t3

    lwc1 $f0, 0($t4)
    swc1 $f0, 0($t5)

    addi $t0, $t0, 1
    j copy_loop_array_bf

end_copy_array_bf:
    
    #––– Init buffer_ptr to start of final_buffer
    la   $t1, final_buffer
    sw   $t1, buffer_ptr
    j print_on_OutputFile
###############################################################################################################################

# Print the file content and number of lines
print_file:
    li $v0, 4
    la $a0, store_file
    syscall
    
    # Print number of lines in the file
    li $v0, 4
    la $a0, msg_lines
    syscall
    li $v0, 1
    lw $a0, size
    syscall
    
    jr $ra

# Exit the program with a message
exit:
    li $v0, 4
    la $a0, Exit
    syscall
    li $v0, 10  
    syscall


# Count the number of lines in the file
count_lines:
    li $t0, 1  # Line counter
    la $t1, store_file

count_loop:
    lb $t2, ($t1)
    beqz $t2, end_count
    beq $t2, 10, increment_count
    addi $t1, $t1, 1
    j count_loop

increment_count:
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j count_loop

end_count:
    # Store the line count in memory
    sw $t0, size
    jr $ra

# Remove newline character from filename input
remove_newline:
    la $t0, filename
newline_loop:
    lb $t1, ($t0)
    beq $t1, 10, replace_newline # ASCII \n = 10
    beqz $t1, done_newline
    addi $t0, $t0, 1 # next char
    j newline_loop

replace_newline:
    sb $zero, ($t0)

done_newline:
    jr $ra # return function 
