!
!  Written by Misael Díaz-Maldonado, 2025.
!  Copyright (c) 2009-2018, Leandro Martínez, Jose Mario Martinez,
!  Ernesto G. Birgin.
!

module cli_parser

    use sizes, only: strl
    use exit_codes, only: exit_code_command_line_error
    use input, only: output_file_name => xyzout
    use input, only: input_file_name

    implicit none

    integer, parameter :: INPUT_FLAG = 0
    integer, parameter :: OUTPUT_FLAG = 1

    private
    public :: parse_command_line_args

contains

function parse_command(cmd) result(res)
    integer :: res
    integer :: idx
    character(*), intent(in) :: cmd
    character(*), parameter :: cmdin = "-i"
    character(*), parameter :: cmdout = "-o"
    character(*), parameter :: errmsg = "ERROR: unrecognized command-line argument: "

    idx = index(cmd, "-i")
    if (idx /= 0) then

        if (len(trim(cmd)) /= len(cmdin)) then
                write(*,*) errmsg // trim(cmd)
                stop exit_code_command_line_error
        end if
        res = INPUT_FLAG

    else

        idx = index(cmd, "-o")
        if (idx == 0) then
                write(*,*) errmsg // trim(cmd)
                stop exit_code_command_line_error
        end if
        if (len(trim(cmd)) /= len(cmdout)) then
                write(*,*) errmsg // trim(cmd)
                stop exit_code_command_line_error
        end if
        res = OUTPUT_FLAG

    end if

    return
end function parse_command

subroutine get_filename(cmdno, filename)
    integer, intent(in) :: cmdno
    character(*), intent(out) :: filename

    call get_command_argument(cmdno + 1, filename)

    return
end subroutine get_filename

subroutine parse_command_line_args
    integer :: idx
    integer :: stat
    integer :: argc
    integer :: cmdno
    integer :: length
    logical :: specified_input_file
    logical :: specified_output_file
    character(len=strl) :: cmd
    character(len=*), parameter :: errmsg = "ERROR: packmol command-line error show help"
    character(len=*), parameter :: errcmp = "ERROR: packmol expects different " // &
        "for the input and output files"

    ! NOTE: Packmol will check the length of these strings later so don't remove this
    input_file_name = ""
    output_file_name = ""
    specified_input_file = .false.
    specified_output_file = .false.

    argc = command_argument_count()
    if (argc == 0) then ! packmol default mode with input redirection

        cmdno = 0
        call get_command_argument(cmdno, value=cmd, length=length, status=stat)
        if (stat == -1) then
            error stop "ERROR: truncation error"
        else if (stat > 0) then
            error stop "ERROR: command-line retrieval error"
        end if

        idx = index(cmd, "packmol")
        if (idx == 0) then
            write (*, *) "WARN: packmol detected non-standard command-line handling"
        end if

        ! NOTE: Packmol expects these to be initialized to empty strings
        if (len(trim(input_file_name)) /= 0) then
            write (*,*) "ERROR: packmol internal error"
            stop exit_code_command_line_error
        end if

        if (len(trim(output_file_name)) /= 0) then
            write (*,*) "ERROR: packmol internal error"
            stop exit_code_command_line_error
        end if

    else if (argc == 4) then ! user has specified both the input and output files

        cmdno = 1
        call get_command_argument(cmdno, value=cmd, length=length, status=stat)
        if (stat == -1) then
            error stop "ERROR: truncation error"
        else if (stat > 0) then
            error stop "ERROR: command-line retrieval error"
        end if

        if (parse_command(cmd) == INPUT_FLAG) then
            call get_filename(cmdno, input_file_name)
            specified_input_file = .true.
        else if (parse_command(cmd) == OUTPUT_FLAG) then
            call get_filename(cmdno, output_file_name)
            specified_output_file = .true.
        else
            error stop "ERROR: packmol received invalid command-line arguments"
        end if

        cmdno = 3
        call get_command_argument(cmdno, value=cmd, length=length, status=stat)
        if (specified_input_file) then
            if (parse_command(cmd) == OUTPUT_FLAG) then
                call get_filename(cmdno, output_file_name)
                specified_output_file = .true.
            end if
        else
            if (parse_command(cmd) == INPUT_FLAG) then
                call get_filename(cmdno, input_file_name)
                specified_input_file = .true.
            else
                error stop "ERROR: packmol received invalid command-line arguments"
            end if
        end if

        ! assertion: both must be true if not we have a logic error in the code
        if (.not. specified_input_file .or. .not. specified_output_file) then
            error stop "ERROR: packmol received invalid command-line arguments"
        end if

        ! NOTE: we want to catch implementation errors in development
        if (len(trim(input_file_name)) == 0) then
            write (*,*) "ERROR: invalid input filename"
            stop exit_code_command_line_error
        end if

        if (len(trim(output_file_name)) == 0) then
            write (*,*) "ERROR: invalid output filename"
            stop exit_code_command_line_error
        end if

        if (trim(input_file_name) == trim(output_file_name)) then
            error stop errcmp
        end if

    else ! user provided invalid command-line arguments
        error stop errmsg
    end if

    return
end subroutine parse_command_line_args

end module cli_parser
