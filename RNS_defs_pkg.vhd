----------------------------------------------------------------------------------
-- Company: SKFU, 4PMI
-- Engineer: prepod, Ionisyan A.S.
-- Project Name: LR3_var(000)
-- formula: c=(a+b)^3-7a+b
-- a,b,c - 32bit BSS numbers
-- RNS primes is (173,229,181,233,239)
----------------------------------------------------------------------------------

--Copyright 2015 Andrey S. Ionisyan
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--    http://www.apache.org/licenses/LICENSE-2.0
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.

-- модуль определений типов данных, констант, хранимых в ROM
-- и вспомогательных подпрограмм
-------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

package RNS_defs_pkg is

--8-битовое целое
subtype uint_8bit is natural range 0 to 255;
--9-битовое целое (используется при обработке результатов 8-бит+8-бит)
subtype uint_9bit is natural range 0 to 511;
--множество всех 8-битных чисел от 0 до 255
type T_uint_8bit_set is array(0 to 255) of uint_8bit;
--множество всех 8-битных чисел от 0 до 511
--используется при табличной выборке результатов операций 8-бит+8-бит
type T_uint_9bit_set is array(0 to 511) of uint_8bit;

--число СОК-регистров микропроцессора
constant RNS_regs_num: natural range 1 to 16 := 8;
--число двоичных регистров микропроцессора
constant bin_regs_num: natural range 1 to 16 := 8;

--число бит в двоичных числах, подавемых на вход микропроцессора и снимаеых с его выхода
--(ширина шины данных микропроцессора)
constant bin_data_width: natural range 1 to 256 := 32;
--тип шины двоичных данных (для передачи шины в подпрограммы и модули)
subtype T_bin_data is unsigned(bin_data_width-1 downto 0);

--тип массивов для храненения вспомогательных величин, например остатков СОК,
--для каждого разряда обрабатываемого двоичного числа.
--используется, например, для описания таблицы значений степеней числа 2, переведенных в СОК
type T_bin_data_width_set is array(0 to bin_data_width-1) of uint_8bit;

--тип для хранения дерева (используется в быстрых алгоритмах бинарного сдваивания)
--если корень имеет индекс i, то левое поддерево имеет индекс 2*i, правое поддерево 2*i+1
type T_tree_array is array(1 to 2*bin_data_width-1)of uint_8bit;

-------------------------------------------------------
--8-битные константы СОК, хранимые в ПЗУ
-------------------------------------------------------
--максимально допустимое число оснований СОК (54 -это числов всех простых 8-битных чисел)
constant RNS_P_num_max: natural range 1 to 54 := 54;
type T_RNS_vector_max is array(1 to RNS_P_num_max) of uint_8bit;

--подпрограмма генерации всех простых числе от 2 до RNS_P_num_max-го простого числа
function gen_primes_8bit return T_RNS_vector_max;
--работает достаточно долго, поэтому имеет смысл заполнить массив простых чисел константами
--если нужна именно генерация, то раскомментировать gen_primes_8bit
constant primes_8bit: T_RNS_vector_max --:= gen_primes_8bit;
 := ( 2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,
      103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,
      199,211,223,227,229,233,239,241,251 );

--число реально используемых оснований СОК
constant RNS_P_num: natural range 1 to RNS_P_num_max := 5;
type T_RNS_vector is array(1 to RNS_P_num) of uint_8bit;
--в массиве RNS_primes_order хранятся номера оснований из главного массива primes_8bit[]
--так, 3-му основанию соответствует 3-е простое число 5, 7- му -> 17, 8-му -> 19.
constant RNS_primes_order: T_RNS_vector := (40,50,42,51,52);
--так как постоянно вести индексную адресацию неудобно, то используется массив RNS_primes[],
--в котором хранятся уже не индексы оснований, а конкретные числа.
function gen_RNS_primes return T_RNS_vector;
constant RNS_primes: T_RNS_vector := gen_RNS_primes;

--------------------------------------------------------
--для быстрого расчета остатков от деления используются таблицы
--размером [число оснований СОК x 512], где вторая размерность 512,
--так как результат сложения, после которого обычно нужно вычислить остаток,
--может превышать 255.
type T_RNS_table_9bit is array(1 to RNS_P_num) of T_uint_9bit_set;

--функция генерации и массив ПЗУ для хранения остатков от деления
--всех 9-битных чисел на все возможные основания СОК.
--первый индекс - номер основания,
--второй индекс - число для которого нужно найти остаток
function gen_RNS_rems_P return T_RNS_table_9bit;
constant RNS_rems_P: T_RNS_table_9bit := gen_RNS_rems_P;

--функция генерации и массив ПЗУ для хранения остатков от деления
--всех 9-битных чисел на значение функции Эйлера от оснований СОК.
--первый индекс - номер основания,
--второй индекс - число для которого нужно найти остаток
function gen_RNS_rems_phi return T_RNS_table_9bit;
constant RNS_rems_phi: T_RNS_table_9bit := gen_RNS_rems_phi;

--таблица значений степеней числа 2, в СОК.
type T_RNS_bin_pows_table is array(1 to RNS_P_num) of T_bin_data_width_set;
function gen_RNS_bin_pows return T_RNS_bin_pows_table; 
constant RNS_bin_pows: T_RNS_bin_pows_table := gen_RNS_bin_pows;

--подпрограмма быстрого вычисления степени m числа n. Результат - остаток от деления на q.
function GF_pow(n,m,q:natural) return natural;
--подпрограмм вычисления первообразного корня поля Галуа по модулю q.
function GF_primitive(q:natural) return natural;

--подпрограмма расчета и массив для хранения всех первообразных корней
--полей Галуа для всех 8-битных простых чисел.
function gen_primitives_8bit return T_RNS_vector_max;
--так как расчет идет медленно, то таблица заполнена заранее вычисленными числами
--однако, можно раскомментировать функцию gen_primitives_8bit
constant primitives_8bit: T_RNS_vector_max --:= gen_primitives_8bit;
 := ( 1, 2, 2, 3, 2, 2, 3, 2, 5, 2, 3, 2, 6, 3, 5, 2, 2, 2, 2,
      7, 5, 3, 2, 3, 5, 2, 5, 2, 6, 3, 3, 2, 3, 2, 2, 6, 5, 2,
      5, 2, 2, 2, 19, 5, 2, 3, 2, 3, 2, 6, 3, 7, 7, 6 );

--так как в проекте используется подмножество простых чисел-оснований СОК,
--то заполняется таблица RNS-primitives - реально используемые первообразные корни
function gen_RNS_primitives return T_RNS_vector;
constant RNS_primitives: T_RNS_vector := gen_RNS_primitives;

--тип массивов-просмотровых таблиц СОК
type T_RNS_table is array(1 to RNS_P_num) of T_uint_8bit_set;

--просмотровая таблица быстрого нахождения обратного индекса (дискретное потенцирование)
--первый индекс - номер основания,
--второй индекс - индекс числа (дискретный логарифм) по которому нужно восстановить число
function gen_RNS_inv_idx_table return T_RNS_table;
constant RNS_inv_idx_table: T_RNS_table := gen_RNS_inv_idx_table;

--просмотровая таблица быстрого нахождения индекса (дискретное логарифмирование)
--первый индекс - номер основания,
--второй индекс - число для которого нужно найти его индекс (дискретный логарифм)
function gen_RNS_idx_table return T_RNS_table;
constant RNS_idx_table: T_RNS_table := gen_RNS_idx_table;

--модулярный сумматор
--j - номер основания
--op1 - первое слагаемое
--op2 - второе слагаемое
function add_mod_8bit(j,op1,op2:uint_8bit) return uint_8bit;

--модулярный умножитель
--j - номер основания
--op1 - первый множитель
--op2 - второй множитель
function mul_mod_8bit(j,op1,op2:uint_8bit) return uint_8bit;

--расчет обратного по умножению элемента поля Галуа по модулю q
--работа основана на теории индексов
-- A^(-1) := inv_idx( q -idx(A) ); q=RNS_primes(j);
-- 0^(-1) :=0; (чтобы не глючило)
function inv_mod_8bit(j,A:uint_8bit) return uint_8bit;

--модулярный формальный делитель (корректно работает только при делении нацело)
--j - номер основания
--op1 - делимое
--op2 - делитель (если op2=0, то возвращается в ответе 0)
function fdiv_mod_8bit(j,op1,op2:uint_8bit) return uint_8bit;

--масштабирование на первое основание СОК
function scale_p1_8bit(A:T_RNS_vector) return T_RNS_vector;

--функция быстрого сложения содержимого массива чисел
--методом бинарного сдваивания (результат берется по модулю RNS_primes(j) )
function add_tree_method(j:uint_8bit; A: T_bin_data_width_set) return uint_8bit;

--функция быстрого перемножения содержимого массива чисел
--методом бинарного сдваиванияр (результат берется по модулю RNS_primes(j) )
function mul_tree_method(j:uint_8bit; A: T_bin_data_width_set) return uint_8bit;

--функция быстрого вычисления скалярного произведения содержимого двух массивов чисел
--методом бинарного сдваиванияр (результат берется по модулю RNS_primes(j) )
function scalar_tree_method(j:uint_8bit; op1,op2: T_bin_data_width_set) return uint_8bit;

--расчет остатка от деления сверхдлинного двоичного числа на простое основание
--каждый бит переводимого числа умножается на соответствующую степень
--двойки, остаток от деления на простое число от которой заранее известен.
--найденные произведения складываются методом бинарного сдваивания
--j - номер основания из таблицы RNS_primes[]
--A - двоичное число
function calc_rem_P(j:uint_8bit; A: T_bin_data) return uint_8bit;

--перевод числа из двоичной системы счисления в СОК
function RNS_conv_PSS_RNS(A: T_bin_data) return T_RNS_vector;

--перевод числа из СОК в ОПСС
--A=(a1,a2,..,a(p_num)) = opss1+opss2*p1+opss3*p1*p2+...+opss(p_num)*p1*p2*..*p(p_num-1)
function RNS_conv_RNS_OPSS(A: T_RNS_vector) return T_RNS_vector;

--перевод числа из ОПСС в СОК
function RNS_conv_OPSS_RNS(A: T_RNS_vector) return T_RNS_vector;

--перевод числа из ОПСС в двоичную систему счисления
function RNS_conv_OPSS_PSS(A: T_RNS_vector) return T_bin_data;

--перевод числа из СОК в двоичную систему счисления
function RNS_conv_RNS_PSS(A: T_RNS_vector) return T_bin_data;

--перевод числа из двоичной системы счисления в ОПСС
function RNS_conv_PSS_OPSS(A: T_bin_data) return T_RNS_vector;

--функция проверки чисел в СОК op1 и op2 на равенство
--result - логический результат (1 - равны, 0 не равны)
function RNS_is_equ(op1,op2:T_RNS_vector) return std_logic;

--функция проверки чисел в СОК op1 и op2 на "op1>op2"
--result - логический результат (1 - op1>op2, 0 иначе)
function RNS_cmp_g(op1,op2:T_RNS_vector) return std_logic;

--функция беззнакового сложения двоичного и 8-битного двоичного чисел
--(в проекте не используется, так как хорошо работает перегруженная "стандартная +")
--function bin_add_int8bit(A: T_bin_data; B:uint_8bit) return T_bin_data;

--функция беззнакового умножения двоичного и 8-битного двоичного чисел
--(перегруженная "стандартная *" глючит)
function bin_mul_uint8bit(A: T_bin_data; B:uint_8bit) return T_bin_data;

end;

---------------------------------------------------------------
--реализации подпрограмм на языке VHDL
---------------------------------------------------------------
package body RNS_defs_pkg is

--при отказе от unsigned в пользу std_logic vector
--subtype T_bin_data is std_logic_vector(bin_data_width-1 downto 0);
----сумматор двоичного числа и 8-битного двоичного числа
----(используется, например, при переводе чисел из ОПСС в ПСС)
--function bin_add_int8bit(A: T_bin_data; B:uint_8bit) return T_bin_data is
--variable res: T_bin_data;
--variable B_stdlgc: std_logic_vector(7 downto 0);
--variable i: natural;
--variable carry: std_logic;
--begin
--   res:=A; B_stdlgc:=conv_std_logic_vector(B,8); carry:='0';
--   for i in 0 to 7 loop
--      res(i) := (A(i) xor B_stdlgc(i)) xor carry;
--      carry:= (A(i) and B_stdlgc(i)) or ((A(i) or B_stdlgc(i)) and carry);
--   end loop;
--   for i in 8 to bin_data_width-1 loop
--      res(i) := A(i) xor carry;
--      carry := carry and A(i);
--   end loop;
--   return res;
--end;
--
----умножитель двоичного числа на 8-битное двоичное число
----(используется, например, при переводе чисел из ОПСС в ПСС)
function bin_mul_uint8bit(A: T_bin_data; B:uint_8bit) return T_bin_data is
variable res: T_bin_data;
variable B_stdlgc: unsigned(7 downto 0);
variable i: natural;
begin
   res:=conv_unsigned(0,bin_data_width);
   if B/=0 then
      B_stdlgc:=conv_unsigned(B,8);
      for i in bin_data_width-1 downto 0 loop
         res:=res+res;
         if A(i)='1' then
            res:=res+B_stdlgc;
         end if;
      end loop;
   end if;           
   return res;
end;
------------------------------------------------------------------------

--генерация всех 8-битных простых чисел от 2 до RNS_P_num_max-го
function gen_primes_8bit return T_RNS_vector_max is
variable i,j,k:natural;
variable is_prime:boolean;
variable p: T_RNS_vector_max;
begin
     p(1):=2;
     i:=2;
     for k in 1 to RNS_p_num_max loop
          is_prime:=false;
          while not(is_prime) loop
               i:=i+1; is_prime:=true;
               for j in 1 to k loop
                   if (i mod p(j))=0 then is_prime:=false; end if;
               end loop;
          end loop;
          if (i<=255)and(k<RNS_p_num_max) then p(k+1):=i; end if;
     end loop;
     return p;
end;

--заполнение массива RNS_primes простыми числами
--согласно индексов, хранимых в массиве RNS_primes_order
function gen_RNS_primes return T_RNS_vector is
variable i: natural;
variable tmp: T_RNS_vector;
begin
   for i in 1 to RNS_p_num loop
      tmp(i) := primes_8bit(RNS_primes_order(i));
   end loop;
   return tmp;
end;

--расчет содержимого массива RNS_rems_P[] - остатков от деления 9-битных чисел на основания СОК
--первый индекс - номер основания
--второй индекс - число, для которого нужно найти остаток от деления
--(используется в модулярном сумматоре )
function gen_RNS_rems_P return T_RNS_table_9bit is
variable i,k:natural;
variable tmp: T_RNS_table_9bit;
begin
   for i in 1 to RNS_P_num loop
      tmp(i)(0):=0;
      for k in 1 to 511 loop
         tmp(i)(k):=k mod RNS_primes(i);
      end loop;
   end loop;
   return tmp;
end;

--расчет содержимого массива RNS_rems_phi[] - остатков от деления 9-битных чисел 
--на функцию Эйлера от оснований СОК
--первый индекс - номер основания
--второй индекс - число, для которого нужно найти остаток от деления
--(используется в модулярном умножителе)
function gen_RNS_rems_phi return T_RNS_table_9bit is
variable i,k:natural;
variable tmp: T_RNS_table_9bit;
begin
   for i in 1 to RNS_P_num loop
      tmp(i)(0):=0;
      for k in 1 to 511 loop
         tmp(i)(k):=k mod (RNS_primes(i)-1);
      end loop;
   end loop;
   return tmp;
end;

--расчет значений степеней числа 2 в СОК
--(используется при переводе двоичных чисел в СОК)
function gen_RNS_bin_pows return T_RNS_bin_pows_table is
variable tmp_table: T_RNS_bin_pows_table;
variable i,k,new_pow: natural;
begin
   for i in 1 to RNS_P_num loop
      tmp_table(i)(0):=1;
      for k in 1 to bin_data_width-1 loop
         new_pow:=tmp_table(i)(k-1)*2;
         tmp_table(i)(k):=RNS_rems_P(i)(new_pow);
      end loop;
   end loop;
   return tmp_table;
end;

--быстрое модулярное возведение числа n в степень m
--результат берется по модулю q
function GF_pow(n,m,q:natural) return natural is
variable res,h,hm:natural;
begin
  res:=1; h:=n; hm:=m;
  while (hm>0) loop 
     if (hm mod 2)=0 then h:=(h*h) mod q; hm:=hm/2;
                     else res:=(res*h) mod q; hm:=hm-1;
     end if;
  end loop;
  return res;
end;

--расчет значения первообразного корня поля Галуа по простому основанию q
function GF_primitive(q:natural) return natural is
variable i,j,flag:natural;
begin
   flag:=0;
   for i in 1 to q-1 loop
      for j in 1 to q-1 loop
         if GF_pow(i,j,q)=1 then flag:=flag+1; end if;
      end loop;
      if flag=1 then return i; else flag:=0; end if;
   end loop;
end;

--вычисление первообразных корней для всех 8-битных простых чисел
function gen_primitives_8bit return T_RNS_vector_max is
variable i:natural;
variable tmp: T_RNS_vector_max;
begin
   for i in 1 to RNS_p_num_max loop
      tmp(i) := GF_primitive(primes_8bit(i));
   end loop;
   return tmp;
end;

--заполнение массива RNS_primitives первообразными корнями
--согласно индексов, хранимых в массиве RNS_primes_order
function gen_RNS_primitives return T_RNS_vector is
variable i: natural;
variable tmp: T_RNS_vector;
begin
   for i in 1 to RNS_p_num loop
      tmp(i) := primitives_8bit(RNS_primes_order(i));
   end loop;
   return tmp;
end;

--расчет просмотровой таблицы дискретного потенцирования
--(по индексу восстанавливается число)
function gen_RNS_inv_idx_table return T_RNS_table is
variable tmp_inv: T_RNS_table;
variable i,k:natural;
begin
   for i in 1 to RNS_p_num loop
      for k in 0 to 255 loop
         tmp_inv(i)(k) := GF_pow(RNS_primitives(i),k,RNS_primes(i));
      end loop;
   end loop;
   return tmp_inv;
end;

--расчет просмотровой таблицы дискретного логарифимирования (индексы)
--(для заданного числа находится его индекс)
function gen_RNS_idx_table return T_RNS_table is
variable tmp_idx: T_RNS_table;
variable i,k:natural;
begin
   for i in 1 to RNS_p_num loop
      for k in 255 downto 0 loop
         tmp_idx(i)(RNS_inv_idx_table(i)(k)):=k;
      end loop;
   end loop;
   return tmp_idx;
end;

--модулярный сумматор
function add_mod_8bit(j,op1,op2:uint_8bit) return uint_8bit is
variable res_9bit: uint_9bit;
begin
   res_9bit := op1 + op2;
   return RNS_rems_P(j)(res_9bit);
end;

--модулярный умножитель
--работа основана на теории индексов
-- op1*op2 := inv_idx( idx(op1) + idx(op2) );
function mul_mod_8bit(j,op1,op2:uint_8bit) return uint_8bit is
variable op1_idx,op2_idx,sum_idx: uint_8bit;
variable res_9bit: uint_9bit;
begin
   if op1=0 then return 0;
   else if op2=0 then return 0;
   else
      op1_idx := RNS_idx_table(j)(op1);
      op2_idx := RNS_idx_table(j)(op2);
      res_9bit := op1_idx + op2_idx;
      sum_idx := RNS_rems_phi(j)(res_9bit);
      return RNS_inv_idx_table(j)(sum_idx);
   end if;
   end if;
end;

--расчет обратного по умножению элемента поля Галуа по модулю q
--работа основана на теории индексов
-- A^(-1) := inv_idx( phi(q) -idx(A) );
-- 0^(-1) :=0; (чтобы не глючило)
function inv_mod_8bit(j,A:uint_8bit) return uint_8bit is
variable A_idx, neg_A_idx: uint_8bit;
begin
   if A=0 then return 0;
          else
      A_idx := RNS_idx_table(j)(A);
      neg_A_idx := (RNS_primes(j)-1)-A_idx;
      return RNS_inv_idx_table(j)(neg_A_idx);
   end if;
end;

--модулярный формальный делитель (корректно работает только при делении нацело)
--j - номер основания
--op1 - делимое
--op2 - делитель (если op2=0, то возвращается в ответе 0)
function fdiv_mod_8bit(j,op1,op2:uint_8bit) return uint_8bit is
variable op2_inv: uint_8bit;
begin
   op2_inv:=inv_mod_8bit(j,op2);
   return mul_mod_8bit(j,op1,op2_inv);
end;

--масштабирование на первое основание СОК
function scale_p1_8bit(A:T_RNS_vector) return T_RNS_vector is
variable A_opss, tmp: T_RNS_vector;
begin
   A_opss:=RNS_conv_RNS_OPSS(A);
   for i in 1 to RNS_P_num -1 loop
      tmp(i):=A_opss(i+1);
   end loop;
   tmp(RNS_P_num):=0;
   return RNS_conv_OPSS_RNS(tmp);
end;

--функция быстрого сложения содержимого массива чисел методом бинарного сдваивания
--результат берется по модулю RNS_primes(j)
function add_tree_method(j:uint_8bit; A: T_bin_data_width_set) return uint_8bit is
variable tree_array: T_tree_array;
variable i: uint_8bit;
begin
   for i in 0 to bin_data_width-1 loop
      tree_array(bin_data_width+i):=A(i);
   end loop;
   for i in bin_data_width-1 downto 1 loop
      tree_array(i) := add_mod_8bit(j,tree_array(2*i), tree_array(2*i+1));
   end loop;
   return tree_array(1);
end;

--функция быстрого перемножения массива чисел методом бинарного сдваивания
--результат берется по модулю RNS_primes(j)
function mul_tree_method(j:uint_8bit; A: T_bin_data_width_set) return uint_8bit is
variable tree_array: T_tree_array;
variable i: uint_8bit;
begin
   for i in 0 to bin_data_width-1 loop
      tree_array(bin_data_width+i):=A(i);
   end loop;
   for i in bin_data_width-1 downto 1 loop
      tree_array(i) := mul_mod_8bit(j,tree_array(2*i), tree_array(2*i+1));
   end loop;
   return tree_array(1);
end;

--функция быстрого вычисления скалярного произведения содержимого двух массивов чисел
--методом бинарного сдваивания (результат берется по модулю RNS_primes(j) )
function scalar_tree_method(j:uint_8bit; op1,op2: T_bin_data_width_set) return uint_8bit is
variable tree_array: T_tree_array;
variable i: uint_8bit;
begin
   for i in 0 to bin_data_width-1 loop
      tree_array(bin_data_width+i):=mul_mod_8bit(j,op1(i),op2(i));
   end loop;
   for i in bin_data_width-1 downto 1 loop
      tree_array(i) := add_mod_8bit(j,tree_array(2*i), tree_array(2*i+1));
   end loop;
   return tree_array(1);
end;

--расчет остатка от деления сверхдлинного двоичного числа на простое основание
--каждый бит переводимого числа умножается на соответствующую степень
--двойки, остаток от деления на простое число от которой заранее известен.
--найденные произведения складываются методом бинарного сдваивания
--j - номер основания из таблицы RNS_primes[]
--A - двоичное число
function calc_rem_P(j:uint_8bit; A:T_bin_data) return uint_8bit is
variable tmp: T_bin_data_width_set;
variable k: uint_8bit;
begin
   for k in 0 to bin_data_width-1 loop
      if A(k)='1' then tmp(k):=RNS_bin_pows(j)(k); else tmp(k):=0; end if;
   end loop;
   return add_tree_method(j,tmp);
end;

--перевод числа из двоичной системы счисления в СОК
------------------------------------------------------------------
function RNS_conv_PSS_RNS(A: T_bin_data) return T_RNS_vector is
variable result: T_RNS_vector;
variable i: uint_8bit;
begin
   for i in 1 to RNS_P_num loop
      result(i) := calc_rem_P(i,A);
   end loop;
   return result;
end;

--перевод числа из СОК в ОПСС
--A=(a1,a2,..,a(p_num)) = opss1+opss2*p1+opss3*p1*p2+...+opss(p_num)*p1*p2*..*p(p_num-1)
function RNS_conv_RNS_OPSS(A: T_RNS_vector) return T_RNS_vector is
variable tmp_res: T_RNS_vector;
variable i,digit: uint_8bit;
variable tmp_add,tmp_neg,tmp_inv: uint_8bit;
begin
   for i in 1 to RNS_P_num loop
      digit := A(i);
      for j in 2 to i loop
         tmp_neg := RNS_primes(i) - RNS_rems_P(i)(tmp_res(j-1));
         tmp_add := add_mod_8bit(i,digit,tmp_neg);
         tmp_inv := inv_mod_8bit(i,RNS_primes(j-1));
         digit := mul_mod_8bit(i,tmp_add,tmp_inv);
      end loop;
      tmp_res(i) := digit;
   end loop;
   return tmp_res;
end;

--функция перевода числа из ОПСС в СОК
function RNS_conv_OPSS_RNS(A: T_RNS_vector) return T_RNS_vector is
variable i,j,tmp_res,tmp_rem,tmp_mul: uint_8bit;
variable result: T_RNS_vector;
begin
      for i in 1 to RNS_P_num loop
         tmp_res := 0;
         for j in RNS_P_num downto 1 loop
            tmp_rem := RNS_rems_P(i)(RNS_primes(j));
            tmp_mul := mul_mod_8bit(i,tmp_res,tmp_rem);
            tmp_res := add_mod_8bit(i,tmp_mul,A(j));
         end loop;
         result(i) := tmp_res;
      end loop;
      return result;
end;
 
--перевод числа из ОПСС в двоичную систему счисления
function RNS_conv_OPSS_PSS(A: T_RNS_vector) return T_bin_data is
variable tmp_res: T_bin_data;
begin
   tmp_res:=conv_unsigned(0,bin_data_width);
   for i in RNS_P_num downto 1 loop
      tmp_res := conv_unsigned(A(i),8) + bin_mul_uint8bit(tmp_res,RNS_primes(i));
   end loop;
   return tmp_res;
end;

--перевод числа из СОК в двоичную систему счисления
function RNS_conv_RNS_PSS(A: T_RNS_vector) return T_bin_data is
variable OPSS_res: T_RNS_vector;
begin
   OPSS_res := RNS_conv_RNS_OPSS(A);
   return RNS_conv_OPSS_PSS(OPSS_res);
end;

--перевод числа из двоичной системы счисления в ОПСС
function RNS_conv_PSS_OPSS(A: T_bin_data) return T_RNS_vector is
variable RNS_res: T_RNS_vector;
begin
   RNS_res := RNS_conv_PSS_RNS(A);
   return RNS_conv_RNS_OPSS(RNS_res);
end;

--функция проверки чисел в СОК op1 и op2 на равенство
--result - логический результат (1 - равны, 0 не равны)
function RNS_is_equ(op1,op2:T_RNS_vector) return std_logic is
variable flag:std_logic;
variable i:uint_8bit;
begin
   flag:='1';
   for i in 1 to RNS_P_num loop
      if op1(i) /= op2(i) then flag := '0'; end if;
   end loop;
   return flag;
end;

--функция проверки чисел в СОК op1 и op2 на "op1>op2"
--result - логический результат (1 - op1>op2, 0 иначе)
function RNS_cmp_g(op1,op2:T_RNS_vector) return std_logic is
variable flag1,flag2:std_logic;
variable op1_opss, op2_opss: T_RNS_vector;
begin
   op1_opss:=RNS_conv_RNS_OPSS(op1);
   op2_opss:=RNS_conv_RNS_OPSS(op2);
   flag1:='0'; flag2:='0';
   for i in RNS_P_num downto 1 loop
      if (flag2='0')and(op1_opss(i)>op2_opss(i)) then flag1:='1'; end if;
      if (flag1='0')and(op2_opss(i)>op1_opss(i)) then flag2:='1'; end if;
   end loop;
   return flag1;
end;

end;