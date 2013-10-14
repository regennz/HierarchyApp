    //
//  HierarchyViewController.m
//  HierarchyApp
//
//  Created by John McKerrell on 15/06/2010.
//  Copyright 2010 MKE Computing Ltd. All rights reserved.
//

#import "HierarchyViewController.h"
#import "ListViewController.h"
#import "ItemListViewController.h"
#import "ItemDetailViewController.h"
#import "ItemWebViewController.h"
#import "WebBrowserViewController.h"

@interface HierarchyViewController ()

@property (nonatomic, readwrite, retain) NSMutableArray *filteredData;
@property (nonatomic, readwrite, retain) NSArray *maindata;
@property (nonatomic, readwrite, retain) NSDictionary *filtersdata;
@property (nonatomic, readwrite, retain) NSDictionary *appdata;
@property (nonatomic, readwrite, retain) NSString *currentCategory;
@property (nonatomic, readwrite, retain) NSMutableArray *currentFilters;
@property (nonatomic, readwrite, retain) NSDictionary *currentItem;
@property (nonatomic, readwrite, retain) NSMutableArray *ignoredFilters;
@property (nonatomic, readwrite) NSUInteger categoryPathPosition;
@property (nonatomic, readwrite, retain) NSDictionary *localizedCategoriesMap;

@end


@implementation HierarchyViewController

@synthesize startCategory = _startCategory;
@synthesize startFilters = _startFilters;
@synthesize startItem = _startItem;
@synthesize extraFilters = _extraFilters;
@synthesize leftMostItem = _leftMostItem;
@synthesize rightBarButtonItem = _rightBarButtonItem;
@synthesize selectModeNavigationItem = _selectModeNavigationItem;
@synthesize extraViewControllers = _extraViewControllers;
@synthesize filteredData = _filteredData;
@synthesize tabBarController = _tabBarController;
@synthesize currentCategory = _currentCategory;
@synthesize currentFilters = _currentFilters;
@synthesize currentItem = _currentItem;
@synthesize tintColor = _tintColor;
@synthesize barStyle = _barStyle;
@synthesize appdata = _appdata;
@synthesize filtersdata = _filtersdata;
@synthesize maindata = _maindata;
@synthesize ignoredFilters = _ignoredFilters;
@synthesize categoryPathPosition = _categoryPathPosition;
@synthesize localizedCategoriesMap = _localizedCategoriesMap;
@synthesize sectionIndexMinimumDisplayRowCount = _sectionIndexMinimumDisplayRowCount;


- (id)initWithAppData:(NSDictionary*)appdata filtersData:(NSDictionary*)filtersdata mainData:(NSArray*)maindata {
    self = [super init];
    if (self) {
        self.appdata = appdata;
        self.filtersdata = filtersdata;
        self.maindata = maindata;
        
        // Retrieve the tint color for nav bars if we have one
        NSDictionary *appearance = [appdata objectForKey:@"appearance"];
        if (appearance ) {
            if ([appearance objectForKey:@"navigationBarTint"]) {
                float red, blue, green, alpha;
                NSScanner *s = [NSScanner scannerWithString:[appearance objectForKey:@"navigationBarTint"]];
                [s setCharactersToBeSkipped:
                 [NSCharacterSet characterSetWithCharactersInString:@"\n, "]];
                if ([s scanFloat:&red] && [s scanFloat:&green] && [s scanFloat:&blue] && [s scanFloat:&alpha] ) {
                    self.tintColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
                }
            }
            
            NSString *barStyle = [appearance objectForKey:@"navigationBarStyle"];
            if (barStyle && ! [@"UIBarStyleDefault" isEqualToString:barStyle] ) {
                self.barStyle = UIBarStyleBlack;
            } else {
                self.barStyle = UIBarStyleDefault;
            }

            
            NSNumber *sectionIndexMinimumDisplayRowCount = [appearance objectForKey:@"sectionIndexMinimumDisplayRowCount"];
            if (sectionIndexMinimumDisplayRowCount) {
                self.sectionIndexMinimumDisplayRowCount = [sectionIndexMinimumDisplayRowCount integerValue];
            } else {
                self.sectionIndexMinimumDisplayRowCount = NSIntegerMax;
            }
        }
        
        // Create an array to hold the filtered data
        self.filteredData = [NSMutableArray arrayWithCapacity:[maindata count]];
        
        // The currently applied filters
        self.currentFilters = [NSMutableArray array];
        self.ignoredFilters = [NSMutableArray array];
        self.extraFilters = [NSArray array];
        self.selectModeNavigationItem = [[[UINavigationItem alloc] init] autorelease];
        
        
    }
    return self;
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    // Create the tab bar showing the right category
    [self setupTabBarWithInitialCategory:self.startCategory];
    [self setCurrentCategory:self.startCategory filters:self.startFilters item:self.startItem];
    self.view = [[[UIView alloc] initWithFrame:self.tabBarController.view.frame] autorelease];
    [self.view addSubview:self.tabBarController.view];
}

-(void) setCurrentCategory:(NSString*)category filters:(NSArray*) filters item:(NSDictionary*)itemData {
    // This is needed to prepare the headings correctly
    [self setCategoryByName:category];
    
    NSArray *oneFilter;
    BOOL oneValidFilter = NO;
    for (oneFilter in filters) {
        if (![self filterProperty:[oneFilter objectAtIndex:0] value:[oneFilter objectAtIndex:1] fromSave:YES]) {
            // If this filter is no longer valid then don't look at following ones.
            break;
        }
        oneValidFilter = YES;
    }
    
    if (oneValidFilter && itemData) {
        [self showItem:itemData fromSave:YES];
    }
    
}

-(BOOL) filter:(NSDictionary*)aFilterData isEqualTo:(NSDictionary*)bFilterData {
    return [[aFilterData objectForKey:@"property"] isEqualToString:[bFilterData objectForKey:@"property"]];
}

-(void)reloadData {
    UINavigationController *navController = ((UINavigationController*)self.tabBarController.selectedViewController);
    id viewController;
    ListViewController *listViewController;
    for (viewController in navController.viewControllers) {
        if ([viewController isKindOfClass:[ListViewController class]]) {
            listViewController = viewController;
            if (listViewController.tableView) {
                [listViewController.tableView reloadData];
            }
        }
    }
}

-(void) updateData:(NSArray*)data {
    if (data == self.maindata) {
        // Do nothing, assume we just need to re-filter
    } else {
        self.maindata = data;
    }
    //NSString *oldCurrentCategory = currentCategory;
    if (self.currentCategory) {
        UINavigationController *navController = ((UINavigationController*)self.tabBarController.selectedViewController);
        // Need to do this or it won't update the data
        
        // Copy the initial filters
        NSArray *oldFilters = [[self.currentFilters copy] autorelease];
        NSMutableArray *oldIgnored = [[self.ignoredFilters mutableCopy] autorelease];
        
        // Empty the current filters
        [self.currentFilters removeAllObjects];
        [self.ignoredFilters removeAllObjects];
        
        // Filter the data (i.e. to be unfiltered)
        [self filterData];
        
        NSDictionary *currentFilter = nil;
        NSArray *headings = nil;
        // Update the data on the first view controller
        ListViewController *viewController = [navController.viewControllers objectAtIndex:0];
        if ([viewController isKindOfClass:[ItemListViewController class]]) {
            [((ItemListViewController*) viewController) updateData:self.filteredData];
        } else {
            currentFilter = [self getCurrentFilterAtPosition:0];
            if (currentFilter) {
                headings = [self filterHeadings:currentFilter];
                [viewController updateData:headings forFilter:currentFilter];
            }
        }
        viewController.navigationItem.rightBarButtonItem = self.rightBarButtonItem;

        
        // Go through the filters
        NSUInteger i, count = [oldFilters count];
        BOOL ignoredLast = NO;
        for (i = 0; i < count; i++) {
            NSArray * filter = [oldFilters objectAtIndex:i];
                    
            // Filter the data
            [self filterDataWhereProperty:[filter objectAtIndex:0] hasValue:[filter objectAtIndex:1]];
        
            if ([self.filteredData count] == 0) {
                --i;
                // Filter again without the last filter
                [self filterData];
                break;
            }
            // Set the filter
            [self.currentFilters addObject:filter];

            currentFilter = [self getCurrentFilterAtPosition:i+1];
            
            
            if (currentFilter) {
                // Retrieve the headings
                headings = [self filterHeadings:currentFilter];
            
                // If there's only one, ignore this filter
                if ( [headings count] == 1
                    && [@"YES" isEqualToString:[currentFilter objectForKey:@"skipSingleEntry"] ]) {
                    if ([oldIgnored count] && [self filter:[oldIgnored objectAtIndex:0] isEqualTo:currentFilter]) {
                        [oldIgnored removeObjectAtIndex:0];
                    } else {
                        NSMutableArray *newControllers = [navController.viewControllers mutableCopy];
                        [newControllers removeObjectAtIndex:(i+1)-[self.ignoredFilters count]];
                        [navController setViewControllers:newControllers animated:NO];
                        [newControllers release];
                    }

                    [self.ignoredFilters addObject:currentFilter];
                    ignoredLast = YES;
                    continue;
                } else if ([oldIgnored count] && [self filter:[oldIgnored objectAtIndex:0] isEqualTo:currentFilter]) {
                    // We must have ignored this last time but don't want to this time
                    ListViewController *viewController = [ListViewController viewControllerDisplaying:currentFilter data:headings];
                    NSMutableArray *newControllers = [NSMutableArray arrayWithCapacity:([navController.viewControllers count]+1)];
                    NSUInteger ip1 = i+1, j = 0, jl = [navController.viewControllers count] + 1;
                    for (; j < jl; ++j) {
                        if (j < ip1) {
                            [newControllers addObject:[navController.viewControllers objectAtIndex:j]];
                        } else if (j > ip1) {
                            [newControllers addObject:[navController.viewControllers objectAtIndex:j-1]];
                        } else {
                            [newControllers addObject:viewController];
                        }
                    }
                    viewController.navigationItem.rightBarButtonItem = self.rightBarButtonItem;
                    [navController setViewControllers:newControllers animated:NO];
                } else {
                // Otherwise update the data on the view controller
                    ListViewController *viewController = [navController.viewControllers objectAtIndex:(i+1)-[self.ignoredFilters count]];
                    if ([viewController isKindOfClass:[ItemListViewController class]]) {
                        break;
                    }
                    if (![viewController updateData:headings forFilter:currentFilter]) {
                        break;
                    }
                    viewController.navigationItem.rightBarButtonItem = self.rightBarButtonItem;

                }
            } else if (i == ([self.currentFilters count] - 1)) {
                // Should be showing an item list
                id viewController = [navController.viewControllers objectAtIndex:(i+1)-[self.ignoredFilters count]];
                if (![viewController isKindOfClass:[ItemListViewController class]]) {
                    break;
                }
                [((ItemListViewController*) viewController) updateData:self.filteredData];
                ((ItemListViewController*) viewController).navigationItem.rightBarButtonItem = self.rightBarButtonItem;

            } else if (i == ([self.currentFilters count]) && self.currentItem) {
                // Check that the currently selected item is still valid?
                NSDictionary *itemData;
                BOOL match = NO;
                for (itemData in self.filteredData) {
                    if ([[itemData objectForKey:@"id"] isEqualToString:[self.currentItem objectForKey:@"id"]]) {
                        match = YES;
                        break;
                    }
                }
                if (!match) {
                    break;
                }
            } else {
                break;
            }

            ignoredLast = NO;
        }
        
        // Get rid of any other view controllers
        NSUInteger numFilters = (i+1) - [self.ignoredFilters count];
        if (numFilters < 1) {
            numFilters = 1;
        }
        while ([navController.viewControllers count] > numFilters) {
            [navController popViewControllerAnimated:NO];
        }
        
        if (ignoredLast) {
            [self filterProperty:[currentFilter objectForKey:@"property"] value:[headings objectAtIndex:0] fromSave:NO];
        }
                          
                          
                          /*
        currentCategory = nil;
        NSArray *scrollPositions = [NSMutableArray arrayWithCapacity:[self.navigationController.viewControllers count]];
        UIViewController *viewController;
        for (viewController in self.navigationController.viewControllers) {
            if (![viewController isKindOfClass:[ListViewController class]]) {
                break;
            }
            
        }
        
        NSArray *filters = [currentFilters copy];
        [self setCurrentCategory:oldCurrentCategory filters:filters item:currentItem];
        [filters release];
         */
    }
}

-(void) startSelectMode {
    ListViewController *visibleController = [((UINavigationController*)self.tabBarController.selectedViewController).viewControllers lastObject];
    [visibleController setSelecting:YES];
}

-(void) stopSelectMode {
    ListViewController *visibleController = [((UINavigationController*)self.tabBarController.selectedViewController).viewControllers lastObject];
    [visibleController setSelecting:NO];
}

-(NSArray*) selectedData {
    ListViewController *visibleController = [((UINavigationController*)self.tabBarController.selectedViewController).viewControllers lastObject];
    NSDictionary *filter = visibleController.displayFilter;
    NSDictionary *itemData, *itemProperties;
    NSArray *selections = [visibleController selectedData];
    id filterProperty;
    NSString *selectedValue;
    NSMutableArray *selectedData = [NSMutableArray arrayWithCapacity:[self.filteredData count]];
    
    // The item list returns all we need anyway.
    if ([visibleController isKindOfClass:[ItemListViewController class]]) {
        return selections;
    }
    
    for (itemData in self.filteredData) {
        itemProperties = [itemData objectForKey:@"properties"];
        BOOL match = NO;
        for (selectedValue in selections) {
            if (filter) {                
                filterProperty = [filter objectForKey:@"property"];
                if ([self property:[itemProperties objectForKey:filterProperty] matchesValue:selectedValue]) {
                    match = YES;
                    break;
                }
            } else {
                if ([selectedValue isEqualToString:[itemData objectForKey:@"title"]]) {
                    match = YES;
                    break;
                }
            }
        }
        if (match) {
            [selectedData addObject:itemData];
        }
    }
    return selectedData;
}

-(void)setupTabBarWithInitialCategory:(NSString*)initialCategory {    
    self.tabBarController = [[[UITabBarController alloc] init] autorelease];
    self.tabBarController.delegate = self;
    NSArray *categories = [self.filtersdata objectForKey:@"categories"];
    NSMutableArray *viewControllers = [NSMutableArray arrayWithCapacity:([categories count]+1)];
    NSMutableDictionary *categoriesMap = [NSMutableDictionary dictionaryWithCapacity:([categories count]+1)];
    NSDictionary *categoryData;
    UIImage *icon;
    UINavigationController *navController;
    UITabBarItem *tabBarItem;
    BOOL doneMainItem = NO;
    NSUInteger selected = 0, i = 0, l = [categories count];
    for (;i < l; ++i) {
        categoryData = [categories objectAtIndex:i];
        icon = [UIImage imageNamed:[categoryData objectForKey:@"icon"]];
        
        navController = [[[UINavigationController alloc] init] autorelease];
        navController.delegate = self;
        if (self.tintColor) {
            navController.navigationBar.tintColor = self.tintColor;
        }
        if (self.barStyle != UIBarStyleDefault) {
            navController.navigationBar.barStyle = self.barStyle;
        }
        [categoriesMap setObject:[categoryData objectForKey:@"title"] forKey:NSLocalizedString([categoryData objectForKey:@"title"],@"")];
        tabBarItem = [[[UITabBarItem alloc] initWithTitle:NSLocalizedString([categoryData objectForKey:@"title"],@"") image:icon tag:i] autorelease];
        navController.tabBarItem = tabBarItem;
        [viewControllers addObject:navController];
        
        if ([initialCategory isEqualToString:NSLocalizedString([categoryData objectForKey:@"title"],@"")]) {
            selected = i;
        }
        if ([@"YES" isEqualToString:[categoryData objectForKey:@"mainItem"]]) {
            doneMainItem = YES;
        }
    }
    
    NSDictionary *itemDescription = [self.appdata objectForKey:@"itemData"];
    if (!doneMainItem && [@"YES" isEqualToString:[itemDescription objectForKey:@"canAppearAsCategory"]]) {
        icon = [UIImage imageNamed:[itemDescription objectForKey:@"categoryIcon"]];
        
        navController = [[[UINavigationController alloc] init] autorelease];
        navController.delegate = self;
        if (self.tintColor) {
            navController.navigationBar.tintColor = self.tintColor;
        }   
        if (self.barStyle != UIBarStyleDefault) {
            navController.navigationBar.barStyle = self.barStyle;
        }        
        [categoriesMap setObject:[itemDescription objectForKey:@"title"] forKey:NSLocalizedString([itemDescription objectForKey:@"title"],@"")];
        tabBarItem = [[[UITabBarItem alloc] initWithTitle:[itemDescription objectForKey:@"title"] image:icon tag:i] autorelease];
        navController.tabBarItem = tabBarItem;
        [viewControllers addObject:navController];        
        
        if ([initialCategory isEqualToString:NSLocalizedString([itemDescription objectForKey:@"title"],@"")]) {
            selected = i;
        }
    }
    
    if (self.extraViewControllers) {
        [viewControllers addObjectsFromArray:self.extraViewControllers];
    }
    
    self.localizedCategoriesMap = [NSDictionary dictionaryWithDictionary:categoriesMap];
    
    [self.tabBarController setViewControllers:viewControllers];
    self.tabBarController.selectedIndex = selected;
    //self.navigationController = (UINavigationController*)tabBarController.selectedViewController;
    
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    //self.navigationController = (UINavigationController*)viewController;
    if (self.extraViewControllers && [self.extraViewControllers indexOfObject:viewController] != NSNotFound) {
        // Don't want to set a category as this is nothing to do with the hierarchy controller.
        self.currentCategory = nil;
        return;
    }
    [self setCategoryByName:[self.localizedCategoriesMap objectForKey:viewController.tabBarItem.title]];
}

-(BOOL)property:(id) property matchesValue:(NSString*) testString {
    if ([testString isEqual: MATCH_ALL]) {
        return YES;
    }
    if ([property isKindOfClass:[NSArray class]]) {
        NSString *propertyValue;
        for (propertyValue in property) {
            if ([testString isEqualToString:propertyValue]) {
                return YES;
            }
        }
        return NO;
    } else {
        return [testString isEqualToString:property];
    }
    
}

-(void)filterData {
    if ([self.currentFilters count] == 0 && [self.extraFilters count] == 0) {
        [self.filteredData setArray:self.maindata];
        return;
    }
    NSDictionary *itemData, *itemProperties;
    NSArray *allFilters, *filter;
    allFilters = [self.extraFilters arrayByAddingObjectsFromArray:self.currentFilters];
    id testValue;
    BOOL match;
    [self.filteredData removeAllObjects];
    for (itemData in self.maindata) {
        match = YES;
        itemProperties = [itemData objectForKey:@"properties"];
        
        for (filter in allFilters) {
            testValue = [itemProperties objectForKey:[filter objectAtIndex:0]];
            if (![self property:testValue matchesValue:[filter objectAtIndex:1]]) {
                match = NO;
                break;
            }
        }
        
        if (match) {
            [self.filteredData addObject:itemData];
        }
    }
}

-(void)filterDataWhereProperty:(NSString*)property hasValue:(NSString*)value {
    NSUInteger i, count = [self.filteredData count];
    NSDictionary *itemData, *itemProperties;
    for (i = 0; i < count; ) {
        itemData = [self.filteredData objectAtIndex:i];
        itemProperties = [itemData objectForKey:@"properties"];
        if ([self property:[itemProperties objectForKey:property] matchesValue:value]) {
            ++i;
        } else {
            [self.filteredData removeObjectAtIndex:i];
            --count;
        }
    }
}

-(NSDictionary*) getCategoryDataByName:(NSString*) category {
    NSArray *categories = [self.filtersdata objectForKey:@"categories"];
    NSDictionary *itemDescription = [self.appdata objectForKey:@"itemData"];
    if ([category isEqualToString:[itemDescription objectForKey:@"title"]]) {
        return itemDescription;
    }
    NSDictionary *categoryData = nil, *searchCategoryData = nil;
    if (category) {
        for (searchCategoryData in categories) {
            if ([category isEqualToString:[searchCategoryData objectForKey:@"title"]]) {
                categoryData = searchCategoryData;
                break;
            }
        }
    } else {
        categoryData = [categories objectAtIndex:0];
    }
    return categoryData;
}

-(void) setCategoryByName:(NSString*) category {
    NSDictionary *categoryData = [self getCategoryDataByName:category];
    if (!categoryData) {
        // Bad data, do nothing
        return;
    }
    
    self.categoryPathPosition = 0;
    [self.currentFilters removeAllObjects];
    [self.ignoredFilters removeAllObjects];
    [self filterData];
    
    UINavigationController *navController = ((UINavigationController*)self.tabBarController.selectedViewController);
    if ([self.currentCategory isEqualToString:[categoryData objectForKey:@"title"]]) {
        [navController popToRootViewControllerAnimated:YES];
    } else {
        self.currentCategory = [categoryData objectForKey:@"title"];
        NSDictionary *currentFilter = [self getCurrentFilterAtPosition:self.categoryPathPosition];
        
        id oldViewController = nil;
        ListViewController *viewController = nil;
        if ([navController.viewControllers count]) {
            [navController popToRootViewControllerAnimated:NO];
            oldViewController = [navController.viewControllers objectAtIndex:0];
            if ([oldViewController isKindOfClass:[ItemListViewController class]]) {
                viewController = oldViewController;
                [((ItemListViewController*)oldViewController) updateData:self.filteredData];
            } else if ([oldViewController isKindOfClass:[ListViewController class]]) {
                NSArray *headings = [self filterHeadings:currentFilter];
                viewController = oldViewController;
                [((ListViewController*)oldViewController) updateData:headings forFilter:currentFilter];
            }
            if (self.leftMostItem) {
                viewController.navigationItem.leftBarButtonItem = nil;
                viewController.navigationItem.leftBarButtonItem = self.leftMostItem;
            }
            if (! viewController.ignoreRightButton) {
                viewController.navigationItem.rightBarButtonItem = self.rightBarButtonItem;
            }
        }
        if (!oldViewController) {
            if (currentFilter) {
                NSArray *headings = [self filterHeadings:currentFilter];
                viewController = [ListViewController viewControllerDisplaying:currentFilter data:headings];
                viewController.hierarchyController = self;
            } else {
                // Show a list of items
                viewController = [ItemListViewController viewControllerDisplaying:[self.appdata objectForKey:@"itemData"] data:self.filteredData];

                viewController.hierarchyController = self;
            }
            if (self.leftMostItem) {
                viewController.navigationItem.leftBarButtonItem = self.leftMostItem;
            }
            if (! viewController.ignoreRightButton) {
                viewController.navigationItem.rightBarButtonItem = self.rightBarButtonItem;
            }
            [navController setViewControllers:[NSArray arrayWithObject:viewController] animated:NO];
        }
        
    }
}

-(NSArray*)filterDataForSearchTerm:(NSString*)string usingFilters:(BOOL)useFilters {
    NSArray *searchData;
    if (useFilters) {
        searchData = self.filteredData;
    } else {
        searchData = self.maindata;
    }
    NSArray *filters = [self.filtersdata objectForKey:@"filters"];
    NSDictionary *itemDescription = [self.appdata objectForKey:@"itemData"];
    NSMutableArray *itemResults = [NSMutableArray arrayWithCapacity:[searchData count]];
    NSMutableDictionary *filterResults = [NSMutableArray arrayWithCapacity:[filters count]];
    
    
    NSDictionary *itemData;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self contains[cd] %@)", string];
    for (itemData in searchData) {
        NSString *title = [itemData objectForKey:@"title"];
        if ([predicate evaluateWithObject:title]) {
            [itemResults addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:title, itemData, nil]
                                                               forKeys:[NSArray arrayWithObjects:@"title", @"itemData", nil]]
             ];
        }
    }
    
    
    
    NSUInteger resultsCapacity = [filterResults count];
    if ([itemResults count]) {
        ++resultsCapacity;
    }
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:resultsCapacity];
    if ([itemResults count]) {
        [results addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[itemDescription objectForKey:@"title"], itemResults, nil]
                                                       forKeys:[NSArray arrayWithObjects:@"type", @"results", nil]]];
    }
    //[results addObjectsFromArray:[filterResults allValues]];
    
    return results;
}

/**
 * This function may be called whether we're going forwards or backwards
 * in a hierarchy. If we're going forwards then everything should add up
 * fine and we won't do anything, if we're going backwards then
 * categoryPathPosition should end up "too big" and we'll know that we
 * need to remove filters until we match the number of viewcontrollers
 * that are visible. Couldn't think of a better way of detecting that we
 * had gone backwards through the hierarchy.
 */
-(void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    BOOL modifiedFilters = NO;
    // The number of navigation controllers will be less if we've ignored filters
    // so we need to add their count on here
    self.categoryPathPosition = ([navigationController.viewControllers count] - 1) + [self.ignoredFilters count];
    
    // Need this to make sure the list row is deselected
    [viewController viewWillAppear:animated];
    
    // Whereas currentFilters still has the ignoredFilters included so should be "right"
    while ([self.currentFilters count] > self.categoryPathPosition) {
        NSArray *removingFilter = [self.currentFilters lastObject];
        NSDictionary *lastIgnoredFilter = [self.ignoredFilters lastObject];
        
        // Now check if the filter we just removed was one that we were ignoring anyway, if it
        // was then we'll need to remove the next one too.
        NSString *removedFilterProperty = [removingFilter objectAtIndex:0];
        if ([removedFilterProperty isEqualToString:[lastIgnoredFilter objectForKey:@"property"]]) {
            [self.ignoredFilters removeLastObject];
            --self.categoryPathPosition;
        }
        [self.currentFilters removeLastObject];
        modifiedFilters = YES;
    }
    
    if (modifiedFilters) {
        [self filterData];
    }
    
    if (self.currentItem && [self.currentFilters count] == self.categoryPathPosition) {
        self.currentItem = nil;
    }
    [self saveCurrentPosition];
    
    if ([viewController isKindOfClass:[ListViewController class]] || !viewController.navigationItem.rightBarButtonItem) {
        if (!([viewController isKindOfClass:[ListViewController class]] && ((ListViewController*)viewController).ignoreRightButton)) {
            // If this bar button as already been assigned then the VC might think it's already showing it when it has actually
            // been assigned to a different VC and is visible there, setting to nil makes sure it adds it to itself
            viewController.navigationItem.rightBarButtonItem = nil;
            viewController.navigationItem.rightBarButtonItem = self.rightBarButtonItem;
        }
    }    
}
/*
 -(BOOL) navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
 [currentFilters removeLastObject];
 return YES;
 }
 */

-(void) saveCurrentPosition {
    // FIXME - this should really be handled by a delegate
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:self.currentFilters forKey:@"startFilters"];
    [userDefaults setObject:self.currentCategory forKey:@"startCategory"];
    [userDefaults setObject:self.currentItem forKey:@"startItem"];
}

-(BOOL) filterProperty:(NSString*)name value:(NSString*)value fromSave:(BOOL) fromSave {
    if (fromSave) {
        NSDictionary *itemData;
        NSDictionary *itemProperties;
        BOOL match = NO;
        for (itemData in self.filteredData) {
            itemProperties = [itemData objectForKey:@"properties"];
            if ([self property:[itemProperties objectForKey:name] matchesValue:value]) {
                match = YES;
                break;
            }
        }
        if (!match) {
            return NO;
        }
    }
    [self.currentFilters addObject:[NSArray arrayWithObjects:name, value, nil]];
    [self filterDataWhereProperty:name hasValue:value];
    
    // Advance to next path position
    ++self.categoryPathPosition;
    NSDictionary *currentFilter = [self getCurrentFilterAtPosition:self.categoryPathPosition];
    
    UIViewController *viewController;
    if (currentFilter) {
        NSArray *headings = [self filterHeadings:currentFilter];
        if ( [headings count] == 1
            && [@"YES" isEqualToString:[currentFilter objectForKey:@"skipSingleEntry"] ]) {
            [self.ignoredFilters addObject:currentFilter];
            // If we're restoring from a saved position then we will have already saved the skip and doing it here
            // will result in a duplicated filter
            if (fromSave) {
                return YES;
            }
            // Skip onto the next filter
            return [self filterProperty:[currentFilter objectForKey:@"property"] value:[headings objectAtIndex:0] fromSave:NO];
        }
        ListViewController *listViewController = [ListViewController viewControllerDisplaying:currentFilter data:headings];
        listViewController.hierarchyController = self;
        viewController = listViewController;
    } else {
        // Show a list of items
        ItemListViewController *itemViewController = [ItemListViewController viewControllerDisplaying:[self.appdata objectForKey:@"itemData"] data:self.filteredData];
        itemViewController.hierarchyController = self;
        viewController = itemViewController;
    }
    [((UINavigationController*)self.tabBarController.selectedViewController) pushViewController:viewController animated:!fromSave];
    return YES;
}

-(NSArray*) filterHeadings:(NSDictionary *)filter {
    NSMutableDictionary *tableHash = [NSMutableDictionary dictionaryWithCapacity:[self.filteredData count]];
    NSDictionary *itemData, *itemProperties;
    id propertyValue, propertySortValue, hashTableValue;
    NSString *itemName, *filterProperty, *filterSortProperty;
    filterProperty = [filter objectForKey:@"property"];
    filterSortProperty = [filter objectForKey:@"sortProperty"];
    for (itemData in self.filteredData) {
        itemProperties = [itemData objectForKey:@"properties"];
        propertyValue = [itemProperties objectForKey:filterProperty];
        propertySortValue = nil;
        if (filterSortProperty) {
            propertySortValue = [itemProperties objectForKey:filterSortProperty];
        }
        if ([propertyValue isKindOfClass:[NSArray class]]) {
            // Property sort value must be an array or it's useless
            if (![propertySortValue isKindOfClass:[NSArray class]]) {
                propertySortValue = nil;
            }
            for (NSUInteger i = 0, l = [propertyValue count]; i < l ; ++i) {
                itemName = [propertyValue objectAtIndex:i];
                if (![tableHash objectForKey:itemName]) {
                    hashTableValue = propertySortValue && i < [propertySortValue count] ? [propertySortValue objectAtIndex:i] : itemName;
                    [tableHash setObject:[NSDictionary dictionaryWithObjectsAndKeys:hashTableValue, @"sortValue", itemName, @"value", nil] forKey:itemName];
                }
            }
        } else if (![tableHash objectForKey:propertyValue]) {
            hashTableValue = propertySortValue ? propertySortValue : propertyValue;
            [tableHash setObject:[NSDictionary dictionaryWithObjectsAndKeys:hashTableValue, @"sortValue", propertyValue, @"value", nil] forKey:propertyValue];
        }
    }
    NSArray *result = [[[tableHash allValues] sortedArrayUsingDescriptors:
            [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"sortValue" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease]]
            ] valueForKey:@"value"];
    return result;
}

-(BOOL) showItem:(NSDictionary*)itemData fromSave:(BOOL) fromSave {
    if (fromSave) {
        NSDictionary *testItemData;
        NSString *itemID = [itemData objectForKey:@"id"];
        BOOL match = NO;
        for (testItemData in self.filteredData) {
            if ([itemID isEqualToString:[testItemData objectForKey:@"id"]]) {
                match = YES;
                break;
            }
        }
        if (!match) {
            return NO;
        }
    }
    
    
    NSString *viewControllerClassString = nil;
    Class viewControllerClass = nil;
    id viewController = nil;
    if ([itemData objectForKey:@"viewController"]) {
        viewControllerClassString = [itemData objectForKey:@"viewController"];
        viewControllerClass = NSClassFromString(viewControllerClassString);
        viewController = [viewControllerClass alloc];
        if ([viewController respondsToSelector:@selector(initWithItem:)]) {
            viewController = [viewController initWithItem:itemData];
        } else {
            viewController = [viewController init];
        }

        if (viewController && [viewController respondsToSelector:@selector(setHierarchyController:)]) {
            [viewController setHierarchyController:self];
        }
    }
    if (!viewController) {
        NSDictionary *itemDataDescription = [self.appdata objectForKey:@"itemData"];
        if (itemDataDescription ) {
            viewControllerClassString = [itemDataDescription objectForKey:@"defaultViewController"];
        }
        if (viewControllerClassString) {
            viewControllerClass = NSClassFromString(viewControllerClassString);
        }
        viewController = [viewControllerClass alloc];
        if ([viewController respondsToSelector:@selector(initWithItem:)]) {
            viewController = [viewController initWithItem:itemData];
        } else {
            viewController = [viewController init];
        }

        if (viewController && [viewController respondsToSelector:@selector(setHierarchyController:)]) {
            [viewController setHierarchyController:self];
        }
    }
    if (viewController) {
        // Do nothing, we're ready
    } else if ([itemData objectForKey:@"htmlfile"] || [itemData objectForKey:@"url"]) {
        viewController = [[ItemWebViewController alloc] initWithItem:itemData];
        ((ItemWebViewController*)viewController).hierarchyController = self;
    } else {
        viewController = [[ItemDetailViewController alloc] initWithItem:itemData];
        ((ItemDetailViewController*)viewController).hierarchyController = self;
    }
    self.currentItem = itemData;
    [((UINavigationController*)self.tabBarController.selectedViewController) pushViewController:viewController animated:!fromSave];
    [viewController release];
    return YES;
}

-(void) loadURLRequestInLocalBrowser:(NSURLRequest*) request {
    WebBrowserViewController *viewController;
    viewController = [[[WebBrowserViewController alloc] initWithRequest:request] autorelease];
    [((UINavigationController*)self.tabBarController.selectedViewController) pushViewController:viewController animated:YES];
    if (self.tintColor) {
        viewController.toolbar.tintColor = self.tintColor;
    }
    if (self.barStyle != UIBarStyleDefault) {
        viewController.toolbar.barStyle = self.barStyle;
    }
}

-(NSDictionary*) getCurrentFilterAtPosition:(NSUInteger)position {
    NSDictionary *categoryData = [self getCategoryDataByName:self.currentCategory];
    
    NSDictionary *filters = [self.filtersdata objectForKey:@"filters"];
    
    NSArray *categoryPath =[categoryData objectForKey:@"path"];
    if (position >= [categoryPath count]) {
        return nil;
    }
    NSString *filterName = [categoryPath objectAtIndex:position];
    return [filters objectForKey:filterName];
}





- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    self.startCategory = nil;
    self.startFilters = nil;
    self.startItem = nil;
    self.extraFilters = nil;
    self.leftMostItem = nil;
    self.rightBarButtonItem = nil;
    self.selectModeNavigationItem = nil;
    self.extraViewControllers = nil;
    self.filteredData = nil;
    self.tabBarController = nil;
    self.currentCategory = nil;
    self.currentFilters = nil;
    self.currentItem = nil;
    self.tintColor = nil;
    self.appdata = nil;
    self.filtersdata = nil;
    self.maindata = nil;
    self.ignoredFilters = nil;
    self.localizedCategoriesMap = nil;
    
    [super dealloc];
}


@end
