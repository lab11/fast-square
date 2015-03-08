function ret = goToSubFolder(cur_folder, file_num)

target_folder_num = floor(file_num/1000);
if(cur_folder == -1)
	target_folder = ['t',num2str(target_folder_num)];
	cd(target_folder);
elseif(cur_folder ~= target_folder_num)
	target_folder = ['t',num2str(target_folder_num)];
	cd ../
	cd(target_folder);
end

ret = target_folder_num;
