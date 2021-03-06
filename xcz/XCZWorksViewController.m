//
//  XCZWorksViewController.m
//  xcz
//
//  Created by 刘志鹏 on 14-6-28.
//  Copyright (c) 2014年 Zhipeng Liu. All rights reserved.
//

#import "XCZWorksViewController.h"
#import "XCZWorkDetailViewController.h"
#import <FMDB/FMDB.h>
#import "XCZWork.h"

@interface XCZWorksViewController ()

@property (nonatomic, strong) NSMutableArray *works;
@property (nonatomic, strong) NSArray *searchResults;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation XCZWorksViewController

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        UINavigationItem *navItem = self.navigationItem;
        navItem.title = @"全部作品";
        
        int index = 0;
        self.works = [[NSMutableArray alloc] init];
        
        // 从SQLite中加载数据
        NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"xcz" ofType:@"db"];
        FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
        if ([db open]) {
            FMResultSet *s = [db executeQuery:@"SELECT * FROM works"];
            while ([s next]) {
                XCZWork *work = [[XCZWork alloc] init];
                work.id = [s intForColumn:@"id"];
                work.title = [s stringForColumn:@"title"];
                work.authorId = [s intForColumn:@"author_id"];
                work.author = [s stringForColumn:@"author"];
                work.dynasty = [s stringForColumn:@"dynasty"];
                work.kind = [s stringForColumn:@"kind"];
                work.kindCN = [s stringForColumn:@"kind_cn"];
                work.foreword = [s stringForColumn:@"foreword"];
                work.content = [s stringForColumn:@"content"];
                work.intro = [s stringForColumn:@"intro"];
                work.layout = [s stringForColumn:@"layout"];
                self.works[index] = work;
                index++;
            }
            
            [db close];
        }
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.searchDisplayController.searchBar.placeholder = @"搜索";
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    NSIndexPath *tableSelection = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:tableSelection animated:YES];
}

// 以下3个message用于解决键盘位置占据了searchResultsTableView下方空间的bug
// 参见：http://stackoverflow.com/questions/19069503/uisearchdisplaycontrollers-searchresultstableviews-contentsize-is-incorrect-b
- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
}

- (void) keyboardWillHide {
    UITableView *tableView = [[self searchDisplayController] searchResultsTableView];
    [tableView setContentInset:UIEdgeInsetsZero];
    [tableView setScrollIndicatorInsets:UIEdgeInsetsZero];
}

// 过滤结果
- (void)filterContentForSearchText:(NSString*)searchText
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"title contains[c] %@", searchText];
    self.searchResults = [self.works filteredArrayUsingPredicate:resultPredicate];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString];
    return YES;
}

// 表行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.searchResults count];
    } else {
        return [self.works count];
    }
}

// 单元格内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"UITableViewCell"];
    }
    
    XCZWork *work = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        work = self.searchResults[indexPath.row];
    } else {
        work = self.works[indexPath.row];
    }
    
    cell.textLabel.text = work.title;
    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"[%@] %@", work.dynasty, work.author];
    return cell;
}

// 选中某单元格后的操作
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XCZWorkDetailViewController *detailController = [[XCZWorkDetailViewController alloc] init];
    
    XCZWork *work = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        work = self.searchResults[indexPath.row];
    } else {
        work = self.works[indexPath.row];
    }
    
    detailController.work = work;
    [self.navigationController pushViewController:detailController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
