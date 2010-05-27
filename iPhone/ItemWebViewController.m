    //
//  ItemWebViewController.m
//  HierarchyApp
//
//  Created by John McKerrell on 26/05/2010.
//  Copyright 2010 MKE Computing Ltd. All rights reserved.
//

#import "ItemWebViewController.h"
#import "AppDelegate_Phone.h"

@implementation ItemWebViewController

-(id) initWithItem:(NSDictionary*)_itemData {
    if ((self = [super init])) {
        itemData = [_itemData retain];
        self.title = [itemData objectForKey:@"title"];
        self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Detail" style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];
        NSLog(@"webView=%@", webView);
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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:[itemData objectForKey:@"htmlfile"]];
    NSURL *url = [NSURL fileURLWithPath:path];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"shouldStartLoad? %i", navigationType);
    if (initialLoadPerformed) {
        AppDelegate_Phone *appDelegate = (AppDelegate_Phone*)[[UIApplication sharedApplication] delegate];
        [appDelegate loadURLRequestInLocalBrowser:request];
        return NO;
    } else {
        initialLoadPerformed = YES;
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"Did start load.");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"Did finish load.");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Did fail load with error: %@", error);
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
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
    [itemData release], itemData = nil;
    [super dealloc];
}


@end
