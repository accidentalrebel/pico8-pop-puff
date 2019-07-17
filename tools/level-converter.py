import sys
import os.path

char_array =  [ '-', '0', 'P', 'F', 'B', '^', '>', 'V', '<', 'S', '!', ']', ';', '[', 'X' ]
alpha_array = [ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' ] 

def open_file(level_string):
    map_string = ''
    moves_count = 0
    with open(level_string,'r') as f:
        lines = []
        line = f.readline()
        lines_count = 0
        while line:
            lines.append(line)
            line = f.readline()
            if lines_count == 5:
                moves_count = line[0]
                
            lines_count += 1

        current_count = 0
        for line in lines:
            if current_count >= lines_count - 5:
                break

            map_string += line.replace('\n','')
            current_count += 1

        f.close()

    return map_string, moves_count

def pad_map_data(map_data):
    i = 0
    for data in map_data:
        if len(data) == 1:
            map_data[i] = '-' + data

        i += 1

    return map_data

def convert_to_hex_representations(map_data):
    string = ''
    a_count = 0
    for data in map_data:
        if data == None or len(data) <= 0:
            break

        first = data[0]
        if first == ' ':
            first = '-'

        if first == '-':
            first = char_array.index(first)
        else:
            first = hex(int(first))[2:]

        second = hex(char_array.index(data[1].upper()))[2:]
        
        string += str(first) + str(second)
        
    print('Hex representation:\t' + string)

    # with open('result.txt','a+') as f:
    #     f.write(string + '\n')
    #     f.close()
    
    return string


def rle(input_string):
    count = 1
    prev = ''
    lst = []
    for character in input_string:
        if character != prev:
            if prev:
                entry = (prev,count)
                lst.append(entry)
                #print lst
            count = 1
            prev = character
        else:
            count += 1
    else:
        try:
            entry = (character,count)
            lst.append(entry)
            return (lst, 0)
        except Exception as e:
            print("Exception encountered {e}".format(e=e)) 
            return (e, 1)

def lzw(uncompressed):
    """Compress a string to a list of output symbols."""
 
    # Build the dictionary.
    dict_size = 256
    dictionary = {chr(i): i for i in range(dict_size)}
 
    w = ""
    result = []
    for c in uncompressed:
        wc = w + c
        if wc in dictionary:
            w = wc
        else:
            result.append(dictionary[w])
            # Add wc to the dictionary.
            dictionary[wc] = dict_size
            dict_size += 1
            w = c
 
    # Output the code for w.
    if w:
        result.append(dictionary[w])
    return result

def convert_map_data(map_data):
    string = ''
    bit_index = 0
    for i in range(len(map_data)):
        data = map_data[i]

        if bit_index == 0:
            if data.isdigit():
                first = int(data)
            else:
                first = char_array.index(data.upper())

            if first > 0:
                string += str(first)

            bit_index += 1
        else:
            second = char_array.index(data.upper())
            string += alpha_array[second]
            bit_index = 0

    print('Converted (' + str(len(string)) + '):\t\t' + string)
    return string

def compress_map_data(map_data):
    prev_char = ''
    string = ''
    count = 0
    for i in range(len(map_data)+1):
        if i >= len(map_data):
            if count > 0:
                string += str(alpha_array[count+15])
            break
            
        current_char = map_data[i]
        if current_char == 'A':
            count += 1
            if count + 15 >= 25:
                string += str(alpha_array[count+15])
                count = 0
        else:
            if count > 0:
                string += str(alpha_array[count+15])
                count = 0
            string += current_char

    print('Compressed (' + str(len(string)) + '): \t' + string)

    return string

def decompress_map_data(map_data):
    string = ''
    for i in range(len(map_data)):
        current_char = map_data[i]
        if current_char.isdigit():
            string += current_char
            continue
        
        index = alpha_array.index(current_char)
        if index >= 15:
            for j in range(index - 15):
                string += 'A'
        else:
            string += current_char

    print('Decompressed: (' + str(len(string)) + '):\t' + string)
    return string

def devert_map_data(map_data):
    string = ''
    was_digit = False
    for i in range(len(map_data)):
        data = map_data[i]
        if data.isdigit():
            string += str(data)
            was_digit = True
        else:
            if not was_digit:
                string += '-'
                
            index = alpha_array.index(data)
            current_char = char_array[index]
            
            string += current_char
            was_digit = False
        
    print('Deverted (' + str(len(string)) + '):\t\t' + string)
    return string

with open('result.txt','w') as f:

    for file_index in range(1,21):
        path = 'levels/level-' + sys.argv[1] + '/' + str('{:03d}'.format(file_index)) + '.txt'
        if not os.path.isfile(path):
            print('Cannot find path: ' + path + '. Exiting...')
            sys.exit()

        map_string, moves_count = open_file(path)

        # test
        # map_string = '-^,->,--,--,1v,-v'
        # map_string = '--,--,--,--,--,--,--,--,--,--,--,--,--,--,--,--,--,--,--,--,--,--,--,--,-v'
        # map_string = '--,-v,--,--,--,--'
        # end_test

        if map_string == '':
            sys.exit()

        map_data = map_string.split(',')
        map_data = pad_map_data(map_data)

        non_compressed_string = ''
        for data in map_data:
            non_compressed_string += data.upper()

        non_compressed_string += str(moves_count)

        print('\nMap ' + str(file_index) + ' string:\t\t' + str(non_compressed_string))

        #map_data = convert_to_hex_representations(map_data)
        original_len = len(non_compressed_string)

        map_data = convert_map_data(non_compressed_string)
        converted_len = len(map_data)

        map_data = compress_map_data(map_data)
        final_map_data = map_data + str(moves_count)
        compressed_len = len(map_data)

        map_data = decompress_map_data(map_data)
        map_data = devert_map_data(map_data)

        if non_compressed_string != map_data:
            raise Exception('Inconsistent conversion results!!!')

        # print('============================================')
        # print('Conversion savings:\t' + str((1 - (converted_len / original_len)) * 100) + '%')
        # print('Compression savings:\t' + str((1 - (compressed_len / converted_len)) * 100) + '%')
        # print('Total savings:\t\t' + str((1 - (compressed_len / original_len)) * 100) + '%')
        # print('============================================')

        print('\nFinal map data:\t' + final_map_data)

        # compressed = lzw(map_data)
        # print('\LZW ' + str(len(compressed)) + ': ' + str(compressed))

        # compressed = rle(map_data)
        # if compressed[1] == 0:
        #     print('RLE is {}'.format(compressed[0]))

        f.write(final_map_data + '\n')
        
    f.close()

    
# -^->----1v-v
# 050600001707
#  F G A A1H H
#  F G R  1H H
